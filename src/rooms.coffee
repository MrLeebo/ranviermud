fs     = require 'fs'
util   = require 'util'
events = require 'events'
_      = require 'underscore'
Data   = require('./data.coffee').Data

rooms_dir = __dirname + '/../entities/areas/'
l10n_dir  = __dirname + '/../l10n/scripts/rooms/'
rooms_scripts_dir = __dirname + '/../scripts/rooms/'

class Rooms
  constructor: ->
    @areas = {}
    @rooms = {}

  load: (verbose, callback) =>
    verbose ||= false
    log = (message) -> util.log message if verbose
    debug = (message) -> util.debug message if verbose
    # Load all the areas into th game
    fs.readdir rooms_dir, (err, files) =>
      return log "For some reason reading the entities directory failed for areas #{err}" if err

      for file in files
        file_path = rooms_dir + file
        continue unless fs.statSync(file_path).isDirectory()

        log "\tExamining area directory - #{file_path}"
        rooms = fs.readdirSync file_path

        # Check for an area manifest
        has_manifest = false
        for room in rooms
          if room.match /manifest.yml/
            has_manifest = true
            break

        return log "\tFailed to load area - #{file_path} - No manifest" unless has_manifest

        try
          manifest = require('js-yaml').load fs.readFileSync(file_path + '/manifest.yml').toString('utf8')
        catch e
          log "\tError loading area manifest for #{file_path} - #{e.message}"
          return

        areacount = 1
        for area of manifest
          unless areacount
            log "\tFound more than one area definition in the manifest for #{file_path} ... skipping"
            break

          unless 'title' in _.keys manifest[area]
            log "\tFailed loading area #{area}, it has no title."
            break

          @areas[area] = manifest[area]
          log "\tLoading area #{@areas[area].title}..."
          areacount--

        # Load any room files
        for room in rooms
          room_path = file_path + '/' + room
          # skip the manifest or any directories
          continue if room.match(/manifest.yml/)
          continue unless fs.statSync(room_path).isFile()

          # parse the room files
          try
            room_def = require('js-yaml').load(fs.readFileSync(room_path).toString('utf8'));
          catch e
            log "\t\tError loading room - #{room_path} - #{e.message}"
            continue

          # create and load the rooms
          for i in [0...room_def.length]
            room = room_def[i]
            validate = ['title', 'description', 'location']

            err = false
            for v in validate
              unless v in _.keys room
                log "\t\tError loading room in file #{room} - no #{v} specified"
                err = true
                break

            continue if err

            log "\t\tLoaded room #{room.location}..."
            room.area = area
            room.filename = room_path
            room.file_index = i
            room = new Room room
            @rooms[room.getLocation()] = room

      log "#{_.keys(@rooms).length} room(s) loaded."

      callback() if callback

  ###
  # Get a room at a specific location
  # @param int location
  # @return Room
  ###
  getAt: (location) =>
    if location.toString() in _.keys @rooms then @rooms[location] else false

  ###
  # Get an area
  # @param string area
  # @return object
  ###
  getArea: (area) =>
    if area in _.keys @areas then @areas[area] else false

class Room extends events.EventEmitter
  constructor: (config) ->
    @title = config.title || ''
    @description = config.description || ''
    @exits = config.exits || []
    @location = config.location || null
    @area = config.area || null
    # these are only set after load, not on construction and is an array of vnums
    @items = []
    @npcs  = []
    @filename = config.filename || ''
    @file_index = config.file_index || null

    Data.loadListeners config, l10n_dir, rooms_scripts_dir, Data.loadBehaviors(config, 'rooms/', @)

  getLocation: => @location
  getArea: => @area
  getExits: => @exits
  getItems: => @items
  getNpcs: => @npcs

  ###
  # Get the description, localized if possible
  # @param string locale
  # @return string
  ###
  getDescription: (locale='en') =>
    if typeof @description == 'string' then @description else if locale in _.keys @description then @description[locale] else 'UNTRANSLATED - Contact an admin'

  ###
  # Get the title, localized if possible
  # @param string locale
  # @return string
  ###
  getTitle: (locale='en') =>
    if typeof @title == 'string' then @title else if locale in _.keys @title then @title[locale] else 'UNTRANSLATED - Contact an admin'

  ###
  # Get the leave message for an exit, localized if possible
  # @param object exit
  # @param strign locale
  # @return string
  ###
  getLeaveMessage: (exit, locale='en') =>
    if typeof exit.leave_message == 'string' then @leave_message else if locale in _.keys @leave_message then @leave_message[locale] else 'UNTRANSLATED - Contact an admin'

  ###
  # Add an item to the quicklookup array for items
  # @param string uid
  ###
  addItem: (uid) => @items.push uid

  ###
  # Remove an item from the room
  # @param string uid
  ###
  removeItem: (uid) =>
    @items = @items.filter (i) -> i != uid

  ###
  # Add an npc to the quicklookup array for npcs
  # @param string uid
  ###
  addNpc: (uid) => @npcs.push uid

  ###
  # Remove an npc from the room
  # @param string uid
  ###
  removeNpc: (uid) =>
    @npcs = @npcs.filter (i) -> i != uid

  ###
  # Check to see if an npc is in the room
  # @param string uid
  # @return boolean
  ###
  hasNpc: (uid) =>
    @npcs.some (i) -> i == uid

  ###
  # Check to see if an npc is in the room
  # @param string uid
  # @return boolean
  ###
  hasItem: (uid) =>
    @items.some (i)-> i == uid

  ###
  # Flatten into a simple structure
  # @return object
  ###
  flatten: =>
    {
      title: @getTitle('en')
      description: @getDescription('en')
      exits: @exits
      location: @location
      area: @area
    }

  ###
  # Get a full object of the room
  # @return object
  ###
  stringify: =>
    {
      title: @title
      description: @description
      exits: @exits
      location: @ocation
      area: @area
    }

exports.Rooms = Rooms
exports.Room = Room
