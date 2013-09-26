CommandUtil = require('../src/command_util').CommandUtil
l10n_file = __dirname + '/../l10n/commands/wield.yml'
l10n = require('../src/l10n')(l10n_file)

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    wield = player.getEquipped 'wield'
    return player.sayL10n l10n, 'CANT_WIELD', items.get(wield).getShortDesc(player.getLocale()) if wield

    thing = CommandUtil.findItemInInventory args.split(' ')[0], player, true
    return player.sayL10n l10n, 'ITEM_NOT_FOUND' unless thing

    thing.emit 'wield', 'wield', player, players
    true
