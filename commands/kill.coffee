CommandUtil = require('../src/command_util').CommandUtil
l10n_file = __dirname + '/../l10n/commands/kill.yml'
l10n = require('../src/l10n')(l10n_file)
exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    room = rooms.getAt player.getLocation()
    npc = CommandUtil.findNpcInRoom npcs, args, room, player, true
    return player.sayL10n l10n, 'TARGET_NOT_FOUND' unless npc
    return player.sayL10n l10n, 'KILL_PACIFIST' unless npc.listeners('combat').length

    npc.emit 'combat', player, room, players, npcs, (success) ->
      # cleanup here...
    true
