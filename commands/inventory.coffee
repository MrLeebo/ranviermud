l10n_file = __dirname + '/../l10n/commands/inventory.yml'
l10n = require('../src/l10n')(l10n_file)

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    player.sayL10n(l10n, 'INV');

    # See how many of an item a player has so we can do stuff like (2) apple
    itemcounts = {}
    player.getInventory().forEach (i) ->
      vnum = i.getVnum()
      (if itemcounts[vnum] then itemcounts[vnum] += 1 else itemcounts[vnum] = 1) unless i.isEquipped()

    displayed = {}
    player.getInventory().forEach (i) ->
      vnum = i.getVnum()
      unless displayed[vnum] or i.isEquipped()
        displayed[vnum] = true

        count = (if itemcounts[vnum] > 1 then '(x' + itemcounts[vnum] + ') ' else '')
        desc = i.getShortDesc player.getLocale()
        player.say "#{count}<magenta>#{desc}</magenta>"
    true
