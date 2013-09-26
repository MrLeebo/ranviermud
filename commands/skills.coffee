Skills = require('../src/skills').Skills
l10n_file = __dirname + '/../l10n/commands/skills.yml'
l10n = require('../src/l10n')(l10n_file)
_ = require 'underscore'

exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    skill_names = _.keys player.getSkills()
    player.sayL10n l10n, "SKILLS"
    return player.sayL10n l10n, "NO_SKILLS" if skill_names.length == 0
    for sk in skill_names
      skill = Skills[player.getAttribute 'class'][sk]
      player.say "<yellow>#{skill.name}</yellow>"

      player.write "  "
      player.sayL10n l10n, "SKILL_DESC", skill.description
      if typeof skill.cooldown != "undefined"
        player.write "  "
        player.sayL10n l10n, "SKILL_COOLDOWN", skill.cooldown
      player.say ""
    true
