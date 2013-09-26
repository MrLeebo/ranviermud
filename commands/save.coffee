l10n_file = __dirname + '/../l10n/commands/save.yml'
l10n = require('../src/l10n')(l10n_file)

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    player.save ->
      player.sayL10n l10n, 'SAVED'
    true
