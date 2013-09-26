l10n_file = __dirname + '/../l10n/commands/channels.yml'
l10n = require('../src/l10n')(l10n_file)
Channels = require('../src/channels').Channels

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    player.sayL10n l10n, 'CHANNELS'
    for ch of Channels
      channel = Channels[ch]
      player.say "<yellow>#{channel.name}</yellow>"
      player.write "  "
      player.say channel.description
    true
