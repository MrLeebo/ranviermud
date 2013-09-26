CommandUtil =
	###
	# Find an item in a room based on the syntax
	#   things like: get 2.thing or look 6.thing or look thing
	# @param string lookString
	# @param Room   room
	# @param Player player
	# @param boolean hydrade Whether to return the id or a full object
	# @return string UUID of the item
	###
	findItemInRoom: (items, lookString, room, player, hydrate) ->
		hydrate ||= false
		thing = CommandUtil.parseDot lookString, room.getItems(), (item) ->
			items.get(item).hasKeyword this.keyword, player.getLocale()

		return false unless thing
		return items.get(thing) if hydrate
		thing

	###
	# Find an npc in a room based on the syntax
	#   things like: get 2.thing or look 6.thing or look thing
	# @param string lookString
	# @param Room   room
	# @param Player player
	# @param boolean hydrade Whether to return the id or a full object
	# @return string UUID of the item
	###
	findNpcInRoom: (npcs, lookString, room, player, hydrate) ->
		hydrate ||= false
		thing = CommandUtil.parseDot lookString, room.getNpcs(), (id) ->
			npcs.get(id).hasKeyword this.keyword, player.getLocale()

		return false unless thing
		return npcs.get(thing) if hydrate
		thing

	###
	# Find an item in a room based on the syntax
	#   things like: get 2.thing or look 6.thing or look thing
	# @param string lookString
	# @param object being This could be a player or NPC. Though most likely player
	# @return string UUID of the item
	###
	findItemInInventory: (lookString, being, hydrate) ->
		hydrate ||= false
		thing = CommandUtil.parseDot lookString, being.getInventory(), (item) ->
			item.hasKeyword this.keyword, being.getLocale()

		return false unless thing
		return thing if hydrate
		thing.getUuid()

	###
	# Parse 3.blah item notation
	# @param string arg    The actual 3.blah string
	# @param Array objects The array of objects to search in
	# @param Function filterFunc Function to filter the list
	# @return object
	###
	parseDot: (arg, objects, filterFunc) ->
		keyword = arg.split(' ')[0]
		multi = false
		nth = null

		# Are they trying to get the nth item of a keyword?
		if /^\d+\./.test keyword
			nth = parseInt keyword.split('.')[0], 10
			keyword = keyword.split('.')[1]
			multi = true

		found = objects.filter filterFunc, {
			keyword: keyword,
			nth: nth
		}

		return false unless found.length
		return found[nth-1] if multi && !isNaN(nth) && nth && nth <= found.length
		found[0]

exports.CommandUtil = CommandUtil
