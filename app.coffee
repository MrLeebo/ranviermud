# built-ins
util = require 'util'
commander = require 'commander'
# local
json = require './package.json'
Commands = require('./src/commands').Commands
Rooms = require('./src/rooms').Rooms
Npcs = require('./src/npcs').Npcs
Items = require('./src/items').Items
Data = require('./src/data').Data
Events = require('./src/events').Events
Plugins = require('./src/plugins')
PlayerManager = require('./src/player_manager').PlayerManager
# third party
Localize = require 'localize'
telnet = require './src/3rdparty/telnet.js'

# storage of main game entities
players = new PlayerManager []
rooms = new Rooms()
items = new Items()
npcs = new Npcs()

# cmdline options
commander
  .version(json.version)
  .option('-s, --save [time]', 'Number of minutes between auto-save ticks [10]', 10)
  .option('-r, --respawn [time]', 'Number of minutes between respawn tickets [20]', 20)
  .option('-p, --port [portNumber]', 'Port to host telnet server [23]', 23)
  .option('-l, --locale [lang]', 'Default locale for the server [en]', 'en')
  .option('-v, --verbose', 'Verbose console logging.')
  .parse(process.argv)

###
# Do the dirty work
###
init = (restart_server) ->
  util.log "START - Loading entities"
  restart_server = if typeof restart_server == 'undefined' then true else restart_server

  config =
    players: players
    items: items
    rooms: rooms
    npcs: npcs
    locale: commander.locale

  Commands.configure config

  Events.configure config

  if (restart_server)
    util.log "START - Starting server"

    ###
    # Effectively the 'main' game loop but not really because it's a REPL
    ###
    server = new telnet.Server (socket) ->
      socket.on 'interrupt', -> socket.write "\n*interrupt*\n"

      # Register all of the events
      for event of Events.events
        socket.on event, Events.events[event]

      socket.write "Connecting...\n"
      util.log "User connected..."
      # @see: src/events.coffee - Events.events.login
      socket.emit 'login', socket

    # start the server
    server.listen commander.port

    # save every 10 minutes
    util.log "Setting autosave to #{commander.save} minutes."
    clearInterval saveint
    saveint = setInterval save, commander.save * 60000

    # respawn every 20 minutes, probably a better way to do this
    util.log "Setting respawn to #{commander.respawn} minutes."
    clearInterval respawnint
    respawnint = setInterval load, commander.respawn * 60000

    config.server = server
    Plugins.init true, config

  load (success) ->
    return process.exit 1 unless success
    util.log "Server started on port: #{commander.port} ..."
    server.emit 'startup'

exports.start = init


###
# Save all connected players
###
save = ->
  util.log "Saving..."
  p.save() for p in players
  util.log "Done"

###
# Load rooms, items, npcs. Register items and npcs to their base locations.
# Configure the event and command modules after load. Doubles as a "respawn"
###
load = (callback) ->
  util.log "Loading rooms..."
  rooms.load commander.verbose, ->
    util.log "Done."

    util.log "Loading items..."
    items.load commander.verbose, ->
      util.log "Done."

      util.log "Adding items to rooms..."
      items.each (item) ->
        if item.getRoom()
          room = rooms.getAt item.getRoom()
          room.addItem item.getUuid() if room and not room.hasItem item.getUuid()
      util.log "Done."

      util.log "Loading npcs..."
      npcs.load commander.verbose, ->
        util.log "Done."

        util.log "Adding npcs to rooms..."
        npcs.each (npc) ->
          if npc.getRoom()
            room = rooms.getAt npc.getRoom()
            room.addNpc npc.getUuid() if room and not room.hasNpc npc.getUuid()
        util.log "Done."

        callback(true) if callback

# Not game stuff, this is for the server executable
process.stdin.setEncoding 'utf8'
l10n = new Localize require('js-yaml').load(require('fs').readFileSync(__dirname + '/l10n/server.yml').toString('utf8')), undefined, 'zz'

###
# Commands that the server executable itself accepts
###
server_commands = {
  ###
  # Hotboot, AKA do everything involved with a restart but keep players connected
  ###
  hotboot: (args) ->
    args = if args then args.split(' ') else []
    warn = args[0] && args[0] == 'warn'
    time = if args[0] then parseInt(args[if warn then 1 else 0], 10) else 0

    return console.log "Gotta give the players a bit longer then that, might as well do it instantly..." if time && time < 20
    time = if time then time * 1000 else 0

    if warn
      warn = (interval) ->
        players.broadcastL10n l10n, 'HOTBOOT_WARN', interval
        p.prompt() for p in players

      warn time / 1000 + " seconds"
      setTimeout ->
        warn Math.floor((time / 4) / 1000) + " seconds"
        , time - Math.floor(time / 4)

    util.log "HOTBOOTING SERVER" + (time ? " IN " + (time / 1000) + " SECONDS " : '')
    setTimeout ->
      util.log "HOTBOOTING..."
      save()
      init false
    , time

  ###
  # Hard restart: saves and disconnects all connected players
  ###
  restart: (args) ->
    args = if args then args.split(' ') else []
    warn = args[0] && args[0] == 'warn'
    time = if args[0] then parseInt(args[if warn then 1 else 0], 10) else 0

    return console.log "Gotta give the players a bit longer then that, might as well do it instantly..." if time && time < 20
    time = if time then time * 1000 else 0

    if warn
      warn = (interval) ->
        players.broadcastL10n l10n, 'RESTART_WARN', interval
        p.prompt() for p in players

      warn time / 1000 + " seconds"
      setTimeout ->
        warn(Math.floor((time / 4) / 1000) + " seconds")
      , time - Math.floor(time / 4)

    util.log "RESTARTING SERVER" + (if time then " IN " + (time / 1000) + " SECONDS " else '')
    setTimeout ->
      util.log "RESTARTING..."
      save()
      server.emit 'shutdown'
      server.close()
      p.getSocket().end() for p in players
      init true
    , time
  }


process.stdin.resume()
process.stdin.on 'data', (data) ->
  data = data.trim()
  command = data.split(' ')[0]

  return console.log "That's not a real command..." unless command in server_commands

  server_commands[command] data.split(' ').slice(1).join(' ')
# vim: set syn=javascript :
