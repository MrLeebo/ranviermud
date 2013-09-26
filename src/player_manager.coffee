class PlayerManager
  constructor: ->
    @players = []
    # this is the default vnum
    @default_location = 1

  ###
  # Get the default location for a player (this is used when they are first created)
  # @return int
  ###
  getDefaultLocation: => @default_location

  ###
  # Get rid of a player
  # @param Player player
  # @param bool   killsock Whether or not to kill their socket
  ###
  removePlayer: (player, killsocket) =>
    killsocket ||= false
    player.getSocket().end() if killsocket
    @players = @players.filter (element) -> element != player

  ###
  # Add a player
  ###
  addPlayer: (player) => @players.push player

  ###
  # Array.prototype.every proxy
  # @param Callback callback
  ###
  every: (callback) => @players.every callback

  ###
  # Execute a function on all players
  # @param Callback callback
  ###
  each: (callback) => @players.forEach callback

  ###
  # Execute a function on all players
  # @param Callback callback
  ###
  some: (callback) => @players.some callback

  ###
  # Execute a function on all players except one
  # @param Player   player
  # @param Callback callback
  ###
  eachExcept: (player, callback) =>
    @players.forEach (p) ->
      callback p unless p == player

  ###
  # Execute a function on all players except those that fail the condition
  # @param Callback callback
  ###
  eachIf: (condition, callback) =>
    @players.forEach (p) ->
      callback p if condition p

  ###
  # Execute a function on all players in a certain location
  # @param int      location
  # @param Callback callback
  ###
  eachAt: (location, callback) =>
    @eachIf ((p) -> p.getLocation() == location), callback


  ###
  # Broadcast a message to every player
  # @param string message
  ###
  broadcast: (message) =>
    @each (p) -> p.say "\r\n" + message

  ###
  # Broadcast a message localized to the individual player's locale
  # @param Localize l10n
  # @param string   key
  # @param ...
  ###
  broadcastL10n: (l10n, key) =>
    locale = l10n.locale
    args = [].slice.call(arguments).slice(1)
    @each (p) ->
      l10n.setLocale p.getLocale() if p.getLocale()
      p.say "\r\n" + l10n.translate.apply(null, args)

    l10n.setLocale locale if locale

  ###
  # Broadcast a message to all but one player
  # @param Player player
  # @param string message
  ###
  broadcastExcept: (player, message) =>
    @eachExcept player, (p) ->
      p.say "\r\n" + message

  ###
  # Broadcast a message localized to the individual player's locale
  # @param Player   player
  # @param Localize l10n
  # @param string   key
  # @param ...
  ###
  broadcastExceptL10n: (player, l10n, key) =>
    locale = l10n.locale
    args = [].slice.call(arguments).slice(2)
    @eachExcept player, (p) ->
      l10n.setLocale p.getLocale() if p.getLocale()

      for i in [0...args.length]
        args[i] = args[i](p) if typeof args[i] == 'function'
      p.say "\r\n" + l10n.translate.apply(null, args)
    l10n.setLocale locale if locale

  ###
  # Broadcast a message to all but one player
  # @param string   message
  # @param function condition
  ###
  broadcastIf: (message, condition) =>
    @eachIf condition, (p) ->
      p.say "\r\n" + message

  ###
  # Broadcast a message to all players in the same location as another player
  # @param string message
  # @param Player player
  ###
  broadcastAt: (message, player) =>
    @eachAt player.getLocation(), (p) -> p.say "\r\n" + message

  ###
   * Broadcast a message localized to the individual player's locale
   * @param Player   player
   * @param Localize l10n
   * @param string   key
   * @param ...
  ###
  broadcastAtL10n: (player, l10n, key) =>
    locale = l10n.locale
    args = [].slice.call(arguments).slice(2)
    @eachAt player.getLocation(), (p) ->
      l10n.setLocale p.getLocale() if p.getLocale()

      for i in [0...args.length]
        args[i] = args[i](p) if typeof args[i] == 'function'
      p.say("\n" + l10n.translate.apply(null, args))
    l10n.setLocale locale if locale

exports.PlayerManager = PlayerManager
