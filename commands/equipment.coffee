l10n_file = __dirname + '/../l10n/commands/equipment.yml'
l10n = require('../src/l10n')(l10n_file)
sprintf = require('sprintf').sprintf
_ = require 'underscore'

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    player.sayL10n l10n, 'EQUIPMENT'
    equipped = player.getEquipped()

    return player.say '<yellow>Nothing</yellow>' if _.isEmpty equipped
    gear = _.values equipped
    for i in [0...gear.length]
      desc = items.get(gear[i]).getShortDesc player.getLocale()
      player.say "<#{i + 1}> <magenta>#{desc}</magenta>"
    true
