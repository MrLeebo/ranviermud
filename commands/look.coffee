util = require 'util'
CommandUtil = require('../src/command_util').CommandUtil
l10n_file = __dirname + '/../l10n/commands/look.yml'
l10n = new require('localize')(require('js-yaml').load(require('fs').readFileSync(l10n_file).toString('utf8')), undefined, 'zz')

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    room = rooms.getAt player.getLocation()

    if args
      # Look at items in the room first
      thing = CommandUtil.findItemInRoom(items, args, room, player, true)
      # Then the inventory
      thing = CommandUtil.findItemInInventory(args, player, true) unless thing
      # Then for an NPC
      thing = CommandUtil.findNpcInRoom(npcs, args, room, player, true) unless thing
      # TODO: Look at players
      # TODO: Look at exits
      # TODO: Look at objects
      return player.sayL10n(l10n, 'ITEM_NOT_FOUND') unless thing

      desc = thing.getDescription player.getLocale()
      player.say desc
      return true

    return player.sayL10n l10n, 'LIMBO' unless room

    # Render the room and its exits
    player.say room.getTitle(player.getLocale())
    player.say room.getDescription(player.getLocale())
    player.say ''

    # display players in the same room
    players.eachIf(
      (p) -> p.getName() != player.getName() and p.getLocation() == player.getLocation(),
      (p) -> player.sayL10n l10n, 'IN_ROOM', p.getName())

    # show all the items in the room
    room.getItems().forEach (id) ->
      desc = items.get(id).getShortDesc player.getLocale()
      player.say "<magenta>#{desc}</magenta>"

    # show all npcs in the room
    room.getNpcs().forEach (id) ->
      npc = npcs.get id
      return true unless npc

      npcLevel = npc.getAttribute 'level'
      pcLevel = player.getAttribute 'level'
      difference = npcLevel - pcLevel

      color = switch
        when difference < -3 then 'grey'
        when difference <= 0 then 'green'
        when difference <= 3 then 'yellow'
        else 'red'

      desc = npcs.get(id).getShortDesc player.getLocale()
      player.say "<#{color}>#{desc}</#{color}>"

    # show exits
    player.write '['
    player.writeL10n l10n, 'EXITS'
    player.write ': '
    room.getExits().forEach (exit) ->
      player.write exit.direction + ' '
    player.say ']'
    true
