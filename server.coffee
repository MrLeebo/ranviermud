#!/usr/bin/env node
###
 * Main file, use this to run the server:
 * node ranvier [options]
 *
 * Options:
 *   -v Verbose loggin
 *   --port Port to listen on
 *   --locale Locale to act as the default
 *   --save Minutes between autosave
 *   --respawn Minutes between respawn
###

# Include the CoffeeScript interpreter so that .coffee files will work
coffee = require 'coffee-script'

# Include our application file
app = require './app.coffee'

# Start the server
app.start()
