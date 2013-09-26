util = require 'util'
_ = require 'underscore'
ansi = require('sty').parse
fs = require 'fs'
CommandUtil = require('./command_util').CommandUtil
l10nHelper = require './l10n'

# Localization
l10n = null
l10n_file = __dirname + '/../l10n/commands.yml'

commands_dir = __dirname + '/../commands/'

rooms = null
players = null
items = null
npcs = null
L = null

###
# Commands a player can execute go here
# Each command takes two arguments: a _string_ which is everything the user
# typed after the command itself, and then the player that typed it.
###
Commands = {
  player_commands : {},

  ###
  # Configure the commands by using a joint players/rooms array
  # and loading the l10n. The config object should look similar to
  # {
  #   rooms: instanceOfRoomsHere,
  #   players: instanceOfPlayerManager,
  #   locale: 'en'
  # }
  # @param object config
  ###
  configure: (config) ->
    rooms   = config.rooms
    players = config.players
    items   = config.items
    npcs    = config.npcs
    util.log "Loading command l10n... "
    # set the "default" locale to zz so it'll never have default loaded and to always force load the English values
    l10n = l10nHelper l10n_file
    l10n.setLocale config.locale
    util.log "Done"

    L = (text) ->
      ansi l10n.translate.apply(null, [].slice.call(arguments))

    # Load external commands
    fs.readdir commands_dir, (err, files) ->
      # Load any pc files
      for file in files
        command_file = commands_dir + file
        continue unless fs.statSync(command_file).isFile()
        continue unless command_file.match /(coffee|js)$/
        command_name = file.split('.')[0]
        Commands.player_commands[command_name] = require(command_file).command(rooms, items, players, npcs, Commands)

  setLocale: (locale) ->
    l10n.setLocale locale
}

###
# Alias commands
# @param string name   Name of the alias E.g., l for look
# @param string target name of the command
###
alias = (name, target, params) ->
  Commands.player_commands[name] = ->
    # Some aliases should replace the argument list.
    args = [].slice.call arguments
    args[0] = params if params
    Commands.player_commands[target].apply null, args

alias 'exp', 'tnl'
alias 'l', 'look'
alias 'n', 'go', 'north'
alias 's', 'go', 'south'
alias 'e', 'go', 'east'
alias 'w', 'go', 'west'

exports.Commands = Commands
