l10n_file = __dirname + '/../l10n/commands/drop.yml'
l10n = require('../src/l10n')(l10n_file)
CommandUtil = require('../src/command_util').CommandUtil

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    room = rooms.getAt player.getLocation()
    item = CommandUtil.findItemInInventory args, player, true

    return player.sayL10n l10n, 'ITEM_NOT_FOUND' unless item
    return player.sayL10n l10n, 'ITEM_WORN' if item.isEquipped()

    desc = item.getShortDesc player.getLocale()
    player.sayL10n l10n, 'ITEM_DROP', desc, false
    room.getNpcs().forEach (id) ->
      npcs.get(id).emit('playerDropItem', room, player, players, item)

    player.removeItem item
    room.addItem item.getUuid()
    item.setInventory null
    item.setRoom room.getLocation()
    true
