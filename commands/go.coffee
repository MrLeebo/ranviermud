_ = require 'underscore'
util = require 'util'
ansi = require('colorize').ansify
l10n_file = __dirname + '/../l10n/commands/go.yml'
l10n = require('../src/l10n')(l10n_file)

exports.command = (rooms, items, players, npcs, Commands) ->
  go = (args, player, is_system_call=false) ->
    try
      room = rooms.getAt player.getLocation()
      unless room
        player.sayL10n l10n, "LIMBO"
        return !is_system_call

      exits = _.filter room.getExits(), (e) ->
        try
          e.direction.match("^" + args)
        catch err
          false

      if exits?.length == 0
        player.sayL10n l10n, "NOT_AN_EXIT" unless is_system_call
        return !is_system_call

      if exits.length > 1
        player.sayL10n l10n, "AMBIG_EXIT"
        return true

      if player.isInCombat()
        player.sayL10n l10n, 'MOVE_COMBAT'
        return true

      move exits.pop(), player
      true
    catch err
      player.say "<red><bold>I'm sorry.</bold> There was a problem going in that direction.</red>" unless is_system_call
      util.error "Error processing go command: #{util.inspect err}"
      !is_system_call

  move = (exit, player) ->
    rooms.getAt(player.getLocation()).emit('playerLeave', player, players)

    room = rooms.getAt exit.location
    unless room
      player.sayL10n l10n, 'LIMBO'
      return false

    # Send the room leave message
    players.broadcastIf exit.leave_message || L('LEAVE', player.getName()), (p) ->
      p.getLocation() == player.getLocation && p != player

    players.eachExcept player, (p) ->
        p.prompt() if p.getLocation() == player.getLocation()

    player.setLocation exit.location
    # Force a re-look of the room
    Commands.player_commands.look null, player

    # Trigger the playerEnter event
    # See example in scripts/npcs/1.js
    room.getNpcs().forEach (id) ->
      npc = npcs.get id
      npc.emit 'playerEnter', room, player, players

    room.emit 'playerEnter', player, players
    true

  L = (text) ->
    ansi l10n.translate.apply null, [].slice.call(arguments)

  go
