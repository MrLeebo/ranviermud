###
# These formulas are stolen straight from WoW.
# See: http://www.wowwiki.com/Formulas:XP_To_Level
###

reduction = (level) ->
  switch
    when level <= 10 then 1
    when level <= 27 then 1 - (level - 10) / 100
    when level <= 59 then .82
    else 1

###
# Difficulty modifier
# @param int level
# @return int
###
diff = (level) ->
  switch
    when level <= 28 then 0
    when level == 29 then 1
    when level == 30 then 3
    when level == 31 then 6
    else 5 * level - 30

###
# Get the exp that a mob gives
# @param int level
# @return int
###
mob_exp = (level) -> 45 + (5 * level)

###
# Helper to get the amount of experience a player needs to level
# @param int level Target level
# @return int
###
level_exp_formula = (level) ->
  ((8 * level) + diff(level)) * mob_exp(level) * reduction(level)

exports.LevelUtil =
  expToLevel: (level) -> level_exp_formula level
  mobExp: (level) -> mob_exp level
