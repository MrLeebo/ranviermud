sprintf = require('sprintf').sprintf
LevelUtil = require('../src/levels').LevelUtil
exports.command = (rooms, items, players, npcs, Commands) ->
  (args, player) ->
    player_exp = player.getAttribute 'experience'
    to_level    = LevelUtil.expToLevel player.getAttribute('level')
    percent    = (player_exp / to_level) * 100

    bar = new Array(Math.floor(percent)).join("=") + new Array(100 - Math.ceil(percent)).join(" ")
    bar = bar.substr(0, 50) + sprintf("%.2f", percent) + "%" + bar.substr(50)
    bar = sprintf "<bgblue><bold><white>%s</white></bold></bgblue> %d/%d", bar, player_exp, to_level

    player.say bar
    true
