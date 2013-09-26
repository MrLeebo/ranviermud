crypto = require 'crypto'
util = require 'util'
ansi = require('colorize').ansify
_ = require 'underscore'
Commands = require('./commands').Commands
Channels = require('./channels').Channels
Data     = require('./data').Data
Item     = require('./items').Item
Player   = require('./player').Player
Skills   = require('./skills').Skills
l10nHelper = require './l10n'

l10n = null
l10n_file = __dirname + '/../l10n/events.yml'
# shortcut for l10n.translate
L  = null

players = null
npcs    = null
rooms   = null
items   = null

# Keep track of password attempts
password_attempts = {}

###
# Helper for advancing staged events
# @param string stage
# @param object firstarg Override for the default arg
###
gen_next = (event) ->
  ###
  # Move to the next stage of a staged event
  # @param Socket|Player arg       Either a Socket or Player on which emit() will be called
  # @param string        nextstage
  # @param ...
  ###
  (arg, nextstage) ->
    func = if arg instanceof Player then arg.getSocket() else arg
    func.emit.apply func, [event].concat([].slice.call(arguments))

###
# Helper for repeating staged events
# @param Array repeat_args
# @return function
###
gen_repeat = (repeat_args, next) ->
  -> next.apply null, [].slice.call(repeat_args)

###
# Events object is a container for any "context switches" for the player.
# Essentially anything that requires player input will have its own listener
# if it isn't just a basic command. Complex listeners are staged.
# See login or createPlayer for examples
###

Events =
  ###
  # Container for events
  # @var object
  ###
  events:
    ###
    # Point of entry for the player. They aren't actually a player yet
    # @param Socket socket
    ###
    login: (arg, stage, dontwelcome, name) ->
      # dontwelcome is used to swallow telnet bullshit
      dontwelcome = if typeof dontwelcome ==-'undefined' then false else dontwelcome
      stage ||= 'intro'

      l10n.setLocale arg.getLocale() if arg instanceof Player

      next   = gen_next 'login'
      repeat = gen_repeat arguments, next

      switch stage
        when 'intro'
          motd = Data.loadMotd()
          arg.write motd if motd
          next arg, 'login'
        when 'login'
          arg.write "Welcome, what is your name? " unless dontwelcome

          arg.once 'data', (name) ->
            # swallow any data that's not from player input i.e., doesn't end with a newline
            # Windows can s@#* a d@#$
            negot = name[name.length - 1] in [0x0a,0x0d]
            return next arg, 'login', true unless negot

            name = name.toString()
            return repeat() unless validateName arg, name

            name = properCase name
            data = Data.loadPlayer name

            # That player doesn't exist so ask if them to create it
            return arg.emit 'createPlayer', arg unless data
            return next arg, 'password', false, name

        when 'password'
          password_attempts[name] = 0 if typeof password_attempts[name] == 'undefined'

          # Boot and log any failed password attempts
          if password_attempts[name] > 2
            arg.write(L('PASSWORD_EXCEEDED') + "\r\n")
            password_attempts[name] = 0
            util.log 'Failed login - exceeded password attempts - ' + name
            arg.end()
            return false

          arg.write L('PASSWORD') unless dontwelcome

          arg.once 'data', (pass) ->
            # Skip garbage
            if pass[0] == 0xFA
              return next arg, 'password', true, name

            pass = crypto.createHash('md5').update(pass.toString('').trim()).digest('hex')
            if pass != Data.loadPlayer(name).password
              arg.write(L('PASSWORD_FAIL') + "\r\n")
              password_attempts[name] += 1
              return repeat()

            next arg, 'done', name
        when 'done'
          name = dontwelcome

          # If there is a player connected with the same name boot them the heck off
          if players.some( (p) -> p.getName() == name)
            players.eachIf(
              (p) -> p.getName() == name,
              (p) ->
                p.emit 'quit'
                players.removePlayer p, true)

          player = new Player arg, Data.loadPlayer(name)
          players.addPlayer player

          player.getSocket().on 'close', -> players.removePlayer player
          players.broadcastL10n l10n, 'WELCOME', player.getName()
          util.log "#{player.getName()} logged in."

          # Load the player's inventory (There's probably a better place to do this)
          inv = []
          player.getInventory().forEach (item) ->
            item = new Item item
            items.addItem item
            inv.push item
          player.setInventory inv

          Commands.player_commands.look null, player
          player.prompt()

          # All that shit done, let them play!
          player.getSocket().emit "commands", player

    ###
    # Command loop
    # @param Player player
    ###
    commands: (player) ->
      # Parse order is commands -> exits -> skills -> channels
      player.getSocket().once 'data', (data) ->
        name = player.getName()
        data = data.toString().trim()
        result = true

        if (data)
          command = data.split(' ').shift()
          args    = data.split(' ').slice(1).join(' ')
          player_command = getCommand command

          try

            switch
              when player_command
                result = Commands.player_commands[player_command] args, player
                util.log "#{name} ran command #{data} with result #{result}"
              #when Commands.room_exits command, player
              when Commands.player_commands['go'] command, player, true
                result = true
                util.log "#{name} moved to #{rooms.getAt(player.getLocation()).getTitle()}"
              when command in _.keys player.getSkills()
                result = player.useSkill command, player, args, rooms, npcs
                util.log "#{name} used skill #{data}"
              when command in _.keys Channels
                Channels[command].use args, player, players
                result = true
                util.log "#{name} spoke in channel #{data}"
              else
                # TODO: Localized string
                player.say command + " is not a valid command."
                result = true
                util.log "#{name} used an unrecognized command: #{data}"

          catch err
            util.error "Unhandled error from player command '#{data}': #{util.inspect err}"
            player.say "<red><bold>I'm sorry.</bold> An error occurred while processing that command.</red>"
            result = true

        if result == false
          util.log "#{player.getName()} is unprompted."
        else
          player.prompt()
          player.getSocket().emit "commands", player

    ###
    # Create a player
    # Stages:
    #   check:  See if they actually want to create a player or not
    #   locale: Get the language they want to play in so we can give them
    #           the rest of the creation process in their language
    #   name:   ... get their name
    #   done:   This is always the end step, here we register them in with
    #           the rest of the logged in players and where they log in
    #
    # @param object arg This is either a Socket or a Player depending on
    #                  the stage.
    # @param string stage See above
    ###
    createPlayer: (arg, stage) ->
      stage ||= 'check'

      l10n.setLocale arg.getLocale() if arg instanceof Player

      next = gen_next 'createPlayer'
      repeat = gen_repeat arguments, next

      ###
      # Multi-stage character creation i.e., races, classes, etc.
      # Always emit 'done' in your last stage to keep it clean
      # Also try to put the cases in order that they happen during creation
      ###
      switch stage
        when 'check'
          arg.write "That player doesn't exist, would you like to create it? [y/n] "
          arg.once 'data', (check) ->
            check = check.toString().trim().toLowerCase();
            return repeat() unless /[yn]/.test(check)

            if check == 'n'
              arg.write "Goodbye!\r\n"
              arg.end()
              return false

            next arg, 'locale'
        when 'locale'
          arg.write "What language would you like to play in? [English, Spanish] "
          arg.once 'data', (locale) ->

            locales =
              english: 'en'
              spanish: 'es'

            locale = locale.toString().trim().toLowerCase()
            unless locale in _.keys locales
              arg.write "Sorry, that's not a valid language.\r\n"
              return repeat()

            arg = new Player arg
            arg.setLocale locales[locale]
            next arg, 'name'
        when 'name'
          arg.write L('NAME_PROMPT')
          arg.getSocket().once 'data', (name) ->
            name = name.toString().trim()
            if /\W/.test(name)
              arg.write(L('INVALID_NAME') + "\r\n")
              return repeat()

            player = false
            players.every (p) ->
              if p.getName().toLowerCase() == name.toLowerCase()
                player = true
                return false
              true

            player ||= Data.loadPlayer name

            if player
              arg.say L('NAME_TAKEN')
              return repeat()

            return repeat() unless validateName arg, name

            # Always give them a name like Shawn instead of sHaWn
            arg.setName properCase name
            next arg, 'password'
        when 'password'
          arg.write L('PASSWORD')
          arg.getSocket().once 'data', (pass) ->
            pass = pass.toString().trim()
            unless pass
              arg.sayL10n l10n, 'EMPTY_PASS'
              return repeat()

            # setPassword handles hashing
            arg.setPassword pass
            next arg, 'class'
        when 'class'
          classes =
            w: '[W]arrior'
          arg.sayL10n l10n, 'CLASS_SELECT'
          for r of classes
            arg.write(classes[r] + "\r\n")

          arg.getSocket().once 'data', (cls) ->
            cls = cls.toString().trim().toLowerCase()
            unless cls in _.keys classes
              arg.sayL10n l10n,'INVALID_CLASS'
              return repeat()

            arg.setAttribute 'class', classes[cls]
            next arg, 'done'
        when 'done'
          # 'done' assumes the argument passed to the event is a player, ...so always do that.
          arg.say 'Welcome to the world!' # TODO: Localize
          arg.setLocation players.getDefaultLocation()
          Commands.player_commands.look null, arg

          # create the pfile then send them on their way
          arg.save ->
            arg.say 'Saved.'
            players.addPlayer arg
            arg.prompt()
            arg.getSocket().emit 'commands', arg

  getNpcs: -> npcs
  getRooms: -> rooms

  configure: (config) ->
    players ||= config.players
    items   ||= config.items
    rooms   ||= config.rooms
    npcs    ||= config.npcs

    unless l10n
      util.log "Loading event l10n... "
      l10n = l10nHelper l10n_file
      util.log "Done"

    l10n.setLocale config.locale

validateName = (arg, name) ->
  # TODO: Localize
  unless name
    arg.write "Please enter a name.\r\n"
    return false

  name = name.toString().trim()
  if name.length < 3 || /[^a-z]/i.test(name)
    arg.write "That's not really your name, now is it?\r\n"
    return false
  true

properCase = (name) ->
  name = name.trim()
  return name if name.length < 2
  name.substr(0, 1).toUpperCase() + name.toLowerCase().substr(1)

getCommand = (command) ->
  # TODO: Implement a BASH like \command to force a command
  # if an exit shares a name
  if command in _.keys Commands.player_commands
    return command

  # Look for a partial command match
  found = false
  for cmd of Commands.player_commands
    try
      regex = new RegExp("^" + command)
      return cmd if cmd.match regex
    catch err
      continue
  false

L = (text) ->
  ansi l10n.translate.apply null, [].slice.call(arguments)

exports.Events = Events
