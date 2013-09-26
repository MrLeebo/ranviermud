fs     = require 'fs'
util   = require 'util'
plugins_dir = __dirname + '/../plugins/'

module.exports =
  init: (verbose, config) ->
    log = (message) -> util.log message if verbose
    debug = (message) -> util.debug message if verbose
    log "Examining plugin directory - " + plugins_dir
    plugins = fs.readdirSync plugins_dir

    # Load any plugin files
    plugins.forEach (plugin) ->
      plugin_dir = plugins_dir + plugin
      return unless fs.statSync(plugin_dir).isDirectory()

      # create and load the plugins
      files = fs.readdirSync plugin_dir

      # Check for an area manifest
      has_init = files.some (file) -> file.match /plugin.js/

      return log "Failed to load plugin - #{plugin} - No plugin.js file" unless has_init

      log "Loading plugin [" + plugin + "]"
      require(plugin_dir + '/plugin.js').init config
      log "Done"
