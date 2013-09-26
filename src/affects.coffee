###
# Put affects you want to reuse in this file
###
exports.Affects =

	###
	# Generic slow
	###
	slow: (config) ->
		original_speed = config.target.getAttribute 'speed'
		{
			activate: ->
				config.target.setAttribute 'speed', original_speed * config.magnitude
			deactivate: ->
				if config.target && config.target.isInCombat()
					config.target.setAttribute 'speed', original_speed
					config.deactivate() if config.deactivate
			duration: config.duration
		}

	###
	# Generic health boost
	###
	, health_boost: (config) ->
		player = config.player
		affect =
			activate: ->
				player.setAttribute 'max_health', player.getAttribute('max_health') + config.magnitude
				player.setAttribute 'health', player.getAttribute('max_health')
			deactivate: ->
				player.setAttribute 'max_health', player.getAttribute('max_health') - config.magnitude
				player.setAttribute 'health', player.getAttribute('max_health')

		affect.duration = config.duration if config.duration
		affect.event = config.event if config.event
		affect;
