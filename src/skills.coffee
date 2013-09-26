Affects  = require('./affects.coffee').Affects

l10n_dir = __dirname + '/../l10n/skills/'
l10ncache = {}
###
# Localization helper
# @return string
###
L = (locale, cls, key, args) ->
  l10n_file = l10n_dir + cls + '.yml'
  l10n = l10ncache[cls+locale] || require('./l10n')(l10n_file)
  l10n.setLocale locale
  l10n.translate.apply(null, [].slice.call(arguments).slice(2))

exports.Skills =
  warrior:
    tackle:
      type: 'active'
      level: 2
      name: "Tackle"
      description: "Tackle your opponent for 120% weapon damage. Target's attacks are slower for 5 seconds following the attack."
      cooldown: 4
      activate: (player, args, rooms, npcs) ->
        target = player.isInCombat()
        unless target
          player.say L(player.getLocale(), 'warrior', 'TACKLE_NOCOMBAT')
          return true

        if player.getAffects 'cooldown_tackle'
          player.say L(player.getLocale(), 'warrior', 'TACKLE_COOLDOWN')
          return true

        damage = Math.min target.getAttribute('max_health'), Math.ceil(player.getDamage().max * 1.2)

        player.say L(player.getLocale(), 'warrior', 'TACKLE_DAMAGE', damage)
        target.setAttribute 'health', target.getAttribute('health') - damage

        unless target.getAffects 'slow'
          target.addAffect 'slow', Affects.slow(
            duration: 3
            magnitude: 1.5
            player: player
            target: target
            deactivate: -> player.say L(player.getLocale(), 'warrior', 'TACKLE_RECOVER'))

        # Slap a cooldown on the player
        player.addAffect 'cooldown_tackle',
          duration: 4,
          deactivate: ->
            player.say L(player.getLocale(), 'warrior', 'TACKLE_COOLDOWN_END')

        true
    battlehardened:
      type: 'passive'
      level: 5
      name: "Battle Hardened"
      description: "Your experience in battle has made you more hardy. Max health is increased by 200"
      activate: (player) ->
        player.removeAffect 'battlehardened' if player.getAffects 'battlehardened'

        player.addAffect 'battlehardened', Affects.health_boost(
          magnitude: 200
          player: player
          event: 'quit')
