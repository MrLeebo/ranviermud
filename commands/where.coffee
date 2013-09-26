exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    room = rooms.getAt player.getLocation()
    player.say room.getArea()
    true
