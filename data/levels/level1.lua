return {
                music = "assets/music/level1.ogg",	
		
				sky = "assets/backgrounds/sky1.png",

				background1 = "assets/backgrounds/mountains1.png",
				background2 = "assets/backgrounds/trees1.png",

				front = "assets/backgrounds/bushes1.png",

				skyScrollSpeed = 15,
				background1ScrollSpeed = 25,
				background2ScrollSpeed = 60,
				groundScrollSpeed = 120,
				frontScrollSpeed = 180,

				skyAutoScroll = true,
				background1AutoScroll = true,
				background2AutoScroll = true,
				groundAutoScroll = true,
				frontAutoScroll = true,	
		
			alwaysRun = true,  --Игрок будет с бегущей анимацией постоянно и анимация стрельбы тоже будет другая

            ground = "assets/tiles/road.png",

            -- Игровая линия: на ней стоят ноги игрока и врагов
            groundTop = 455,

            -- Визуально дорога начинается выше
            groundVisualY = 425,

            -- И растягивается вниз
            groundVisualHeight = 130,

			--Монстры генерируюся
            generate_enemies = true,
		
			------Плотность появления монстров
			min_spawn_delay = 1.8,
			max_spawn_delay = 3.2,		
-----------------------
			--duration = 20,
			--Нужно только для уровне й с generate_enemies = true
			--первые 20 секунд враги появляются случайно;
			--после 20 секунд новые враги перестают появляться;
			--когда игрок добьёт/переживёт всех оставшихся врагов на экране;
			--уровень считается завершённым;
			--игра переходит на следующий уровень.	
			---ЕСЛИ generate_enemies = false	
			--duration не нужен. Там враги идут по списку
			--Когда список закончился и на экране не осталось врагов — уровень завершён.			
--------------------------			
			enemySpawners = {
				{
					type = "enemy_spawner",

					x = "right",
					offsetX = 20,

					minSpawnDelay = 1.8,
					maxSpawnDelay = 3.2,

					enemies = {
						{
							model = "Bat",
							spawnChance = 15
						},
						{
							model = "FlyingShooter",
							spawnChance = 8,
							y = 120,
							speed = 100
						},
						{
							model = "BatBomber",
							spawnChance = 28
						},
						{
							model = "Slime",
							spawnChance = 45
						},
						{
							model = "Goblin",
							spawnChance = 30
						},
						{
							model = "Shooter",
							spawnChance = 15
						},
						{
							model = "Jumper",
							spawnChance = 10
						}
					}
				}
			},
			levelEnd = {
					model = "DefaultExit",
					x = 650,
					y = 360,
					---время появления. Если не указано то стандартное (20)
					appearAfter = 10,
					ShowTimer = true	
				},
            enemies = {			
				{
					model = "Bat",
					spawnChance = 15
				},
				{
					model = "FlyingShooter",
					spawnChance = 8,
					y = 120,
					speed = 100
				},
				{
					model = "BatBomber",
					spawnChance = 28	
					-----опционально
					--    y = 120,
					--	speed = 120,
					--	health = 3
				},			
                {
                    model = "Slime",
					spawnChance = 45
                },
                {
                    model = "Goblin",
					spawnChance = 30,					
                },
				{
					model = "Shooter",
					spawnChance = 15
				},
				{
					model = "Jumper",
					spawnChance = 10,					
				}
			},
			platforms = {
				{
					model = "WoodPlatform",
					x = 260,
					y = 330,
					PlatformScrollSpeed = 0
				},
				{
					model = "MovingPlatform",
					x = 620,
					y = 370
				},
				{
					model = "RaisedGround",
					x = 420,
					y = 385
					---Можно и эти параметры здесь писать
				    --w = 220,
					--PlatformScrollSpeed = 60
				}
			},	
			hazards = {
				{
					model = "PitSmall",
					x = 500,
					y = 425,
					HazardScrollSpeed = 120
				}
			},
			healthPickups = {
				{
					model = "HealthSmall",
					x = 700,
					y = 330
				},
				{
					model = "HealthSmall",
					x = 760,
					y = 220,

					speed = 80,
					appearAfter = 5
				}
			},	
		decors = {
				{
					model = "TreeBig",
					x = 300,
					y = 260,
					speed = 120
				},
				{
					model = "RockSmall",
					x = 520,
					y = 420,
					speed = 120
				},
				{
					model = "Fire",
					x = 820,
					y = 360,
					speed = 120
				}
		}		
}