CommandUtil = require('../src/command_util').CommandUtil
l10n_file = __dirname + '/../l10n/commands/wear.yml'
l10n = require('../src/l10n')(l10n_file)

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    wear = player.getEquipped 'wear'

    return player.sayL10n l10n, 'CANT_WEAR', items.get(wear).getShortDesc(player.getLocale()) if wear

    thing = CommandUtil.findItemInInventory args.split(' ')[0], player, true
    return player.sayL10n l10n, 'ITEM_NOT_FOUND' unless thing

    thing.emit 'wear', 'wear', player, players
    true
