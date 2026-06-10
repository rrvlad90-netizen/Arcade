return {
type = "slime",
sprite_folder = "assets/enemies/slime",
w = 38,
h = 42,
----настройка вероятности появления монстра для generate режима
---Код сам нормализует.
---Важно: если хотя бы у одного врага указан spawnChance, то враги без spawnChance будут иметь шанс 0. 
--Это удобно, чтобы случайно не спавнить незапланированного монстра.

spawnChance = 45,
					
speed = 130,
damage = 1,
score = 1,
taunt = true,
					
DissaperWheOutOfScreen = 100,
color = {0.25, 0.8, 0.35}
}