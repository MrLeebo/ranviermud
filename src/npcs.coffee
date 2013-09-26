fs       = require 'fs'
util     = require 'util'
uuid     = require 'node-uuid'
events   = require 'events'
_        = require 'underscore'
Data     = require('./data.coffee').Data

npcs_dir         = __dirname + '/../entities/npcs/'
npcs_scripts_dir = __dirname + '/../scripts/npcs/'
l10n_dir         = __dirname + '/../l10n/scripts/npcs/'

###
# Npc container class. Loads/finds npcs
###
class Npcs
  constructor: ->
    @npcs = {}
    @load_count = {}

  ###
  # Load NPCs from the configs
  # @param boolean verbose Whether to do verbose logging
  # @param callback
  ###
  load: (verbose, callback) =>
    verbose ||= false
    log = (message) -> util.log message if verbose
    debug = (message) -> util.debug message if verbose

    log "\tExamining npc directory - #{npcs_dir}"
    npcs = fs.readdir npcs_dir, (err, files) =>
      # Load any npc files
      for file in files
        npc_file = npcs_dir + file
        continue unless fs.statSync(npc_file).isFile()
        continue unless npc_file.match(/yml$/)

        # parse the npc files
        try
          npc_def = require('js-yaml').load fs.readFileSync(npc_file).toString('utf8')
        catch e
          log "\t\tError loading npc - #{npc_file} - #{e.message}"
          continue

        # create and load the npcs
        npc_def.forEach (npc) =>
          validate = ['keywords', 'short_description', 'vnum']

          for v in validate
            return log "\t\tError loading npc in file #{npc_file} - no #{v} specified" unless v in _.keys npc

          # max load for npcs so we don't have 1000 npcs in a room due to respawn
          if @load_count[npc.vnum] && @load_count[npc.vnum] >= npc.load_max
            return log "\t\tMaxload of #{npc.load_max} hit for npc #{npc.vnum}"

          npc = new Npc npc
          npc.setUuid uuid.v4()
          log "\t\tLoaded npc [uuid:#{npc.getUuid()}, vnum:#{npc.vnum}]"
          @add npc

      callback() if callback

  ###
  # Add an npc and generate a uuid if necessary
  # @param Npc npc
  ###
  add: (npc) =>
    npc.setUuid uuid.v4() unless npc.getUuid()
    @npcs[npc.getUuid()] = npc
    @load_count[npc.vnum] = if @load_count[npc.vnum] then @load_count[npc.vnum] + 1 else 1

  ###
  # Gets all instance of an npc
  # Not sure exactly what you'd use this method for as you would most likely
  # rather act upon a single instance of an item
  # @param int vnum
  # @return Npc
  ###
  getByVnum: (vnum) =>
    objs = []
    @each (o) ->
      objs.push(o) if o.getVnum() == vnum
    objs

  ###
  # retrieve an instance of an npc by uuid
  # @param string uid
  # @return Npc
  ###
  get: (uid) => @npcs[uid]

  ###
  # proxy Array.each
  # @param function callback
  ###
  each: (callback) =>
    callback @npcs[npc] for npc of @npcs

  ###
  # Blows away an NPC
  # WARNING: If you haven't removed the npc from the room it's in shit _will_ break
  # @param Npc npc
  ###
  destroy: (npc) =>
    delete @npcs[npc.getUuid()]

###
# Actual class for NPCs
###
class Npc extends events.EventEmitter
  constructor: (config) ->
    @short_description = config.short_description || ''
    @keywords          = config.keywords    || []
    @description       = config.description || ''
    @behaviors         = config.behaviors || ''
    @room              = config.room        || null
    @vnum              = config.vnum
    @affects = {}
    @uuid = null
    @in_combat = false

    @attributes =
      max_health: 0
      health: 0
      level: 1

    for i of config.attributes || {}
      @attributes[i] = config.attributes[i]

    Data.loadListeners config, l10n_dir, npcs_scripts_dir, Data.loadBehaviors(config, 'npcs/', @)

  ###
  # Mutators
  ###
  getVnum: => @vnum
  getInv: => @inventory
  isInCombat: => @in_combat
  getRoom: => @room
  getUuid: => @uuid
  getBehaviors: => @behaviors
  getAttribute: (attr) => if typeof @attributes[attr] != 'undefined' then @attributes[attr] else false
  setUuid: (uuid) => @uuid = uuid
  setRoom: (room) => @room = room
  setInventory: (identifier) => @inventory = identifier
  setInCombat: (combat) => @in_combat = combat
  setContainer: (uid) => @container = uid
  setAttribute: (attr, val) => @attributes[attr] = val
  removeAffect: (aff) => delete @affects[aff]

  ###
  # Get currently applied affects
  # @param string aff
  # @return Array|Object
  ###
  getAffects: (aff) =>
    if aff
      return if typeof @affects[aff] != 'undefined' then @affects[aff] else false
    @affects

  ###
  # Add, activate and set a timer for an affect
  # @param string name
  # @param object affect
  ###
  addAffect: (name, affect) =>
    affect.activate() if affect.activate

    setTimeout( =>
      affect.deactivate() if affect.deactivate
      @removeAffect name
    , affect.duration * 1000)
    @affects[name] = 1

  ###
  # Get the description, localized if possible
  # @param string locale
  # @return string
  ###
  getDescription: (locale) =>
    if typeof @description == 'string' then @description else if locale in _.keys @description then @description[locale] else 'UNTRANSLATED - Contact an admin'

  ###
  # Get the title, localized if possible
  # @param string locale
  # @return string
  ###
  getShortDesc: (locale) =>
    if typeof @short_description == 'string' then @short_description else if locale in _.keys @short_description then @short_description[locale] else 'UNTRANSLATED - Contact an admin'

  ###
  # Get the title, localized if possible
  # @param string locale
  # @return string
  ###
  getKeywords: (locale) =>
    if Array.isArray(@keywords) then @keywords else if locale in _.keys @keywords then @keywords[locale] else ['UNTRANSLATED - Contact an admin']

  ###
  # check to see if an npc has a specific keyword
  # @param string keyword
  # @param string locale
  # @return boolean
  ###
  hasKeyword: (keyword, locale) =>
    @getKeywords(locale).some (word) -> keyword == word

  ###
  # Get attack speed of a player
  # @return float
  ###
  getAttackSpeed: =>
    @getAttribute('speed') || 1

  ###
  # Get the damage a player can do
  # @return int
  ###
  getDamage: =>
    base = [1, 20]
    damage = if @getAttribute('damage') then @getAttribute('damage').split('-').map (i) -> parseInt i, 10 else base
    {
      min: damage[0]
      max: damage[1]
    }

exports.Npcs = Npcs
exports.Npc  = Npc
