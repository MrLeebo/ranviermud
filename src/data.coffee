fs   = require 'fs'
path = require 'path'
util = require 'util'
l10nHelper = require './l10n'

data_path = __dirname + '/../data/'
behaviors_dir      = __dirname + '/../scripts/behaviors/'
behaviors_l10n_dir = __dirname + '/../l10n/scripts/behaviors/'

Data =
  ###
  # load the MOTD for the intro screen
  # @return string
  ###
  loadMotd: ->
    fs.readFileSync(data_path + 'motd').toString 'utf8'

  ###
  # Load a player's pfile.
  # This does not instantiate a player, it simply returns data
  # @param string name Player's name
  # @return object
  ###
  loadPlayer: (name) ->
    player_path = "#{data_path}players/#{name}.json"
    return false unless fs.existsSync player_path

    # This currently doesn't work seemingly due to a nodejs bug so... we'll do it the hard way
    # return require(playerpath);
    JSON.parse fs.readFileSync(player_path).toString('utf8')

  ###
  # Save a player
  # @param Player player
  # @param function callback
  # @return boolean
  ###
  savePlayer: (player, callback) ->
    player_path = "#{data_path}players/#{player.getName()}.json"
    fs.writeFileSync player_path, player.stringify(), 'utf8'
    callback() if callback

  ###
  # Load and set listeners onto an object
  # @param object config
  # @param string l10n_dir
  # @param object target
  # @return object The applied target
  ###
  loadListeners: (config, l10n_dir, scripts_dir, target) ->
    # Check to see if the target has scripts, if so load them
    if config['script']
      listeners = require(scripts_dir + config.script).listeners
      # the localization file for the script will be l10n/scripts/<script name>.yml
      # example: l10n/scripts/1.js.yml
      l10n_file = l10n_dir + config.script + '.yml'
      l10n = l10nHelper l10n_file
      util.log 'Loaded script file ' + l10n_file
      for listener of listeners
        target.on listener, listeners[listener](l10n)

    target

  ###
  # Load and set behaviors (predefined sets of listeners) onto an object
  # @param object config
  # @param string subdir The subdirectory of behaviors_dir which the behaviors live
  # @param object target
  # @return object The applied target
  ###
  loadBehaviors: (config, subdir, target) ->
    if config['behaviors']
      behaviors = config.behaviors.split ','
      # reverse to give left-to-right weight in the array
      behaviors.reverse().forEach (behavior) ->
        l10n_file = behaviors_l10n_dir + subdir + behavior + '.yml'
        l10n = l10nHelper l10n_file
        listeners = require(behaviors_dir + subdir + behavior + '.js').listeners
        for listener of listeners
          # For now do not allow conflicting listeners in behaviors
          target.removeAllListeners listener
          target.on listener, listeners[listener](l10n)

    target

exports.Data = Data
