exports.Channels =
	say:
		name: 'say'
		description: 'Talk to those around you'
		use: (args, player, players) ->
			args = args.replace "\x33", ''
			players.broadcastAt "<bold><cyan>#{player.getName()}</cyan></bold> says '#{args}'", player
			players.eachExcept player, (p) ->
				p.prompt() if p.getLocation() == player.getLocation()

	chat:
		name: 'chat'
		description: 'Talk to everyone online'
		use: (args, player, players) ->
			args = args.replace "\x33", ''
			players.broadcast "<bold><magenta>[chat] #{player.getName()}: #{args}</magenta></bold>", player
			players.eachExcept player, (p) ->
				p.prompt()
