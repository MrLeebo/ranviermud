fs = require 'fs'
util = require 'util'
uuid = require 'node-uuid'
events = require 'events'
_ = require 'underscore'
Data = require('./data.coffee').Data

objects_dir = __dirname + '/../entities/objects/'
l10n_dir    = __dirname + '/../l10n/scripts/objects/'
objects_scripts_dir = __dirname + '/../scripts/objects/'

class Items
  constructor: ->
    @objects = {}
    @load_count = {}

  getScriptsDir: =>
    objects_scripts_dir

  getL10nDir: =>
    l10n_dir

  load: (verbose, callback) =>
    verbose ||= false
    log = (message) -> util.log message if verbose
    debug = (message) -> util.debug message if verbose

    log "\tExamining object directory - #{objects_dir}"
    objects = fs.readdir objects_dir, (err, files) =>
      # Load any object files
      for file in files
        object_file = objects_dir + file
        continue unless fs.statSync(object_file).isFile()
        continue unless object_file.match(/yml$/)

        # parse the object files
        try
          object_def = require('js-yaml').load(fs.readFileSync(object_file).toString('utf8'))
        catch e
          log "\t\tError loading object - #{object_file} - #{e.message}"
          continue

        # create and load the objects
        object_def.forEach (object) =>
          validate = ['keywords', 'short_description', 'vnum']

          for v in validate
            return log "\t\tError loading object in file #{file} - no #{v} specified" unless v in _.keys object

          # max load for items so we don't have 1000 items in a room due to respawn
          if (@load_count[object.vnum] && @load_count[object.vnum] >= object.load_max)
            return log "\t\tMaxload of #{object.load_max} hit for object #{object.vnum}"

          object = new Item object
          object.setUuid uuid.v4()
          log "\t\tLoaded item [uuid:#{object.getUuid()}, vnum:#{object.vnum}]"
          @addItem object

      callback() if callback

  ###
  # Add an item and generate a uuid if necessary
  # @param Item item
  ###
  addItem: (item) =>
    item.setUuid uuid.v4() unless item.getUuid()
    @objects[item.getUuid()] = item
    @load_count[item.vnum] = if @load_count[item.vnum] then @load_count[item.vnum] + 1 else 1

  ###
  # Gets all instance of an object
  # @param int vnum
  # @return Item
  ###
  getByVnum: (vnum) =>
    objs = []
    @each (o) ->
        objs.push(o) if o.getVnum() == vnum
    objs

  ###
  # retrieve an instance of an object by uuid
  # @param string uid
  # @return Item
  ###
  get: (uid) =>
    @objects[uid]

  ###
  # proxy Array.each
  # @param function callback
  ###
  each: (callback) =>
    callback @objects[obj] for obj of @objects

class Item extends events.EventEmitter
  constructor: (config) ->
    @short_description = config.short_description || ''
    @keywords = config.keywords || []
    @description = config.description || ''
    @inventory = config.inventory || null
    @room = config.room || null
    @npc_held = config.npc_held || null
    @equipped = config.equipped || null
    @container = config.container || null
    @uuid = config.uuid || null
    @vnum = config.vnum || null
    @script = config.script || ''
    @attributes = config.attributes || {}

    Data.loadListeners config, l10n_dir, objects_scripts_dir, Data.loadBehaviors(config, 'objects/', @)

  ###
  # Mutators
  ###
  getVnum: => @vnum
  getInv: => @inventory
  isNpcHeld: => @npc_held
  isEquipped: => @equipped
  getRoom: => @room
  getContainer: => @container
  getUuid: => @uuid
  getAttribute: (attr) => @attributes[attr] || false
  setUuid: (uuid) => @uuid = uuid
  setRoom: (room) => @room = room
  setInventory: (identifier) => @inventory = identifier
  setNpcHeld: (held) => @npc_held = held
  setContainer: (uid) => @container = uid
  setEquipped: (equip) => @equipped = !!equip
  setAttribute: (attr, val) => @attributes[attr] = val

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
    if Array.isArray @keywords then @keywords else if locale in _.keys @keywords then @keywords[locale] else ['UNTRANSLATED - Contact an admin']

  ###
  # check to see if an item has a specific keyword
  # @param string keyword
  # @param string locale
  # @return boolean
  ###
  hasKeyword: (keyword, locale) =>
    @getKeywords(locale).some (word) -> keyword == word

  ###
  # Used when saving a copy of an item to a player
  # @return object
  ###
  flatten: =>
    uuid: @uuid
    keywords: @keywords
    short_description: @short_description
    description: @description
    inventory: @inventory     # Player or Npc object that is holding it
    vnum: @vnum
    script: @script
    equipped: @equipped
    attributes: @attributes

exports.Items = Items
exports.Item  = Item
