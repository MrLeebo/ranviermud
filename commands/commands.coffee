sprintf = require('sprintf').sprintf
l10n_file = __dirname + '/../l10n/commands/commands.yml'
l10n = require('../src/l10n')(l10n_file)
_ = require 'underscore'

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    commands = (command for command of Commands.player_commands)
    longest = _.max commands, (c) -> c.length
    commands.sort()

    player.sayL10n l10n, 'COMMANDS'
    for i in [0...commands.length]
      player[if (i + 1) % 5 == 0 then 'say' else 'write'](sprintf("%-#{longest.length + 1}s", commands[i]))
    true
