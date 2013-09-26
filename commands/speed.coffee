l10n_file = __dirname + '/../l10n/commands/speed.yml'
l10n = require('../src/l10n')(l10n_file)

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    players.each (p) ->
      player.sayL10n l10n, 'SPEED', p.getAttackSpeed()
    true
