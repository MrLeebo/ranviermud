l10n_file = __dirname + '/../l10n/commands/get.yml'
l10n = require('../src/l10n')(l10n_file)
CommandUtil = require('../src/command_util').CommandUtil
exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    # No picking stuff up in combat
    return player.sayL10n l10n, 'GET_COMBAT' if player.isInCombat()
    return player.sayL10n l10n, 'CARRY_MAX' if player.getInventory().length >= 20

    room = rooms.getAt player.getLocation()
    item = CommandUtil.findItemInRoom(items, args, room, player)
    return player.sayL10n l10n, 'ITEM_NOT_FOUND' unless item

    item = items.get item
    desc = item.getShortDesc player.getLocale()

    player.sayL10n l10n, 'ITEM_PICKUP', desc
    item.setRoom null
    item.setInventory player.getName()
    player.addItem item
    room.removeItem item.getUuid()
    true
