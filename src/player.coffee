Data    = require('./data').Data
Skills  = require('./skills').Skills
crypto  = require 'crypto'
ansi    = require 'sty'
util    = require 'util'
events  = require 'events'
_       = require 'underscore'

npcs_scripts_dir = __dirname + '/../scripts/player/'
l10n_dir         = __dirname + '/../l10n/scripts/player/'

class Player extends events.EventEmitter
  constructor: (@socket, data = {}) ->
    @name = data.name || ''
    @location = data.location || null
    @locale = data.locale || null
    @prompt_string = data.prompt_string || '%health/%max_healthHP>'
    @combat_prompt = "<bold><red>[COMBAT]</red> [%health/%max_healthHP] %target_name: [%target_health/%target_max_health]</bold>\r\n>"
    @password = data.password || null
    @inventory = data.inventory || []
    @equipment =  data.equipment || {}
    # In combat is either false or an NPC vnum
    @in_combat = false
    @attributes = data.attributes || {
      max_health: 100
      health: 100
      level: 1
      experience: 0
      class: ''
    }

    @affects = {}
    @skills = data.skills || {}

    for skill of @skills
      @useSkill skill, @ if Skills[@getAttribute('class')][skill].type == 'passive'

    Data.loadListeners {script: "player.js"}, l10n_dir, npcs_scripts_dir, @

  ###
  # Mutators
  ###
  getPrompt: => @prompt_string
  getCombatPrompt: => @combat_prompt
  getLocale: => @locale
  getName: => @name
  getLocation: => @location
  getSocket: => @socket
  getInventory: => @inventory
  getAttribute: (attr) => typeof @attributes[attr] != 'undefined' && @attributes[attr]
  getSkills: (skill) => if typeof @skills[skill] != 'undefined' then @skills[skill] else @skills
  getPassword: => @password
  isInCombat: => @in_combat
  setPrompt: (str) => @prompt_string = str
  setCombatPrompt: (str) => @combat_prompt = str
  setLocale: (locale) => @locale = locale
  setName: (newname) => @name = newname
  setLocation: (loc) => @location = loc
  setPassword: (pass) => @password = crypto.createHash('md5').update(pass).digest('hex')
  addItem: (item) => @inventory.push item
  removeItem: (item) => @inventory = @inventory.filter (i) -> item != i
  setInventory: (inv) => @inventory = inv
  setInCombat: (combat) => @in_combat = combat
  setAttribute: (attr, val) => @attributes[attr] = val
  addSkill: (name, skill) => @skills[name] = skill

  ###
  # Get currently applied affects
  # @param string aff
  # @return Array|Object
  ###
  getAffects: (aff) =>
    return typeof @affects[aff] != 'undefined' && @affects[aff] if aff
    @affects

  ###
  # Add, activate and set a timer for an affect
  # @param string name
  # @param object affect
  ###
  addAffect: (name, affect) =>
    affect.activate() if affect.activate

    deact = =>
      if affect.deactivate
        affect.deactivate()
        @prompt()

      @removeAffect name

    if affect.duration
      affect.timer = setTimeout deact, affect.duration * 1000
    else if affect.event
      @on affect.event, deact

    @affects[name] = affect

  removeAffect: (aff) =>
    if @affects[aff].event
      @removeListener @affects[aff].event, @affects[aff].deactivate
    else
      clearTimeout @affects[aff].timer
    delete @affects[aff]

  ###
  # Get and possibly hydrate an equipped item
  # @param string  slot    Slot the item is equipped in
  # @param boolean hydrate Return an actual item or just the uuid
  # @return string|Item
  ###
  getEquipped: (slot, hydrate) =>
    return @equipment unless slot
    return false unless slot in _.keys @equipment

    hydrate ||= false
    return @equipment[slot] unless hydrate
    @getInventory().filter((i) => i.getUuid() == @equipment[slot])[0]

  ###
  # "equip" an item
  # @param string wear_location The location this item is worn
  # @param Item   item
  ###
  equip: (wear_location, item) =>
    @equipment[wear_location] = item.getUuid()
    item.setEquipped true

  ###
  # "unequip" an item
  # @param Item   item
  ###
  unequip: (item) =>
    item.setEquipped false
    for i in _.keys @equipment
      if @equipment[i] == item.getUuid()
        delete @equipment[i]
        break

    item.emit 'remove', @

  ###
  # Write to a player's socket
  # @param string data Stuff to write
  ###
  write: (data, color) =>
    color ||= true
    ansi.disable() unless color
    @socket.write ansi.parse(data)
    ansi.enable()

  ###
  # Write based on player's locale
  # @param Localize l10n
  # @param string   key
  # @param ...
  ###
  writeL10n: (l10n, key) =>
    locale = l10n.locale
    l10n.setLocale @getLocale() if @getLocale()

    @write l10n.translate.apply(null, [].slice.call(arguments).slice(1))
    l10n.setLocale locale if locale

  ###
  # write() + newline
  # @see write
  ###
  say: (data, color) =>
    @write data + "\r\n", color

  ###
  # writeL10n() + newline
  # @see writeL10n
  ###
  sayL10n: (l10n, key) =>
    locale = l10n.locale
    l10n.setLocale @getLocale() if @getLocale()

    @say l10n.translate.apply(null, [].slice.call(arguments).slice(1))
    l10n.setLocale locale if locale

  ###
  # Display the configured prompt to the player
  # @param object extra Other data to show
  ###
  prompt: (extra = {}) =>
    @_prompt @getPrompt(), extra

  ###
  # @see prompt
  ###
  combatPrompt: (extra = {}) =>
    @_prompt @getCombatPrompt(), extra

  _prompt: (pstring, extra) =>
    for attr of @attributes
      pstring = pstring.replace "%" + attr, @attributes[attr]

    for data of extra
      pstring = pstring.replace "%" + data, extra[data]

    pstring = pstring.replace /%[a-z_]+?/, ''
    @write "\r\n" + pstring

  ###
  # Save the player... who'da thunk it.
  # @param function callback
  ###
  save: (callback) =>
    Data.savePlayer @, callback

  ###
  # Get attack speed of a player
  # @return float
  ###
  getAttackSpeed: =>
    weapon = @getEquipped 'wield', true
    if weapon then weapon.getAttribute 'speed' || 1 else 1

  ###
  # Get the damage a player can do
  # @return int
  ###
  getDamage: =>
    weapon = @getEquipped 'wield', true
    base = [1, 20]
    return base unless weapon
    return base unless weapon.getAttribute 'damage'

    damage = weapon.getAttribute('damage').split('-').map (i) -> parseInt i, 10

    {
      min: damage[0],
      max: damage[1]
    }

  ###
  # Turn the player into a JSON string for storage
  # @return string
  ###
  stringify: =>
    inv = []
    @getInventory().forEach (item) ->
      inv.push item.flatten()

    JSON.stringify
      name: @name
      location: @location
      locale: @locale
      prompt_string: @prompt_string
      combat_prompt: @combat_prompt
      password: @password
      inventory: inv
      equipment: @equipment
      attributes: @attributes
      skills: @skills

  ###
  # Helper to activate skills
  # @param string skill
  ###
  useSkill: (skill, args) =>
    Skills[@getAttribute('class')][skill].activate.apply null, [].slice.call(arguments).slice(1)

# Export the Player class so you can use it in
# other files by using require("Player").Player
exports.Player = Player
