l10n_file = __dirname + '/../l10n/commands/quit.yml'
l10n = require('../src/l10n')(l10n_file)

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    return player.sayL10n(l10n, 'COMBAT_COMMAND_FAIL') if player.isInCombat()

    player.sayL10n l10n, 'GAME_QUIT'
    player.emit 'quit'
    player.save ->
      players.removePlayer player, true
    false
