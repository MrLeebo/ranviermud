CommandUtil = require('../src/command_util').CommandUtil
l10n_file = __dirname + '/../l10n/commands/remove.yml'
l10n = require('../src/l10n')(l10n_file)

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    thing = CommandUtil.findItemInInventory args.split(' ')[0], player, true
    return player.sayL10n l10n, 'ITEM_NOT_FOUND' unless thing
    return player.sayL10n l10n, 'ITEM_NOT_EQUIPPED' unless thing.isEquipped()

    player.unequip thing
    true
