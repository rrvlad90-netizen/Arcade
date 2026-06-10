--Так как у flying_shooter пока используется старый формат sprite_folder, он будет искать:
--assets/enemies/flying_shooter/fly_1.png
--assets/enemies/flying_shooter/fly_2.png
--........
--И выстрел будет происходить на attack_3.png, потому что attackEventFrame = 3



return {
type = "bat",
sprite_folder = "assets/enemies/bat",

flying = true,

w = 42,
h = 32,

-- Можно задать точную высоту
y = 180,

-- Или не задавать y, а использовать высоту над землёй
-- flyHeight = 180,

-- Лёгкое покачивание вверх-вниз
---Можно вообще не указывать flyAmplitude, потому что по умолчанию он уже 0
flyAmplitude = 12,    --Если поставить 0, враг будет лететь ровно по прямой без движения вверх-вниз:
flyFrequency = 4,

speed = 110,
damage = 1,
score = 2,

health = 1,
showHealthBar = false,

spawnChance = 15,

DissaperWheOutOfScreen = 100,
color = {0.45, 0.9, 1.0}
}