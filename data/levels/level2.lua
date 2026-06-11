return {
            music = "assets/music/level2.ogg",

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

            groundTop = 455,
            groundVisualY = 395,
            groundVisualHeight = 130,

            enemies = {
				{
					model = "Goblin",
					x = 520,
					spawnDistance = 800
				},
				{
					model = "Shooter",
					x = 760,
					spawnDistance = 800
				},
				{
					model = "Bat",
					x = 900,
					y = 150,
					spawnDistance = 800
				}
			},
			levelEnd = {
			model = "DefaultExit",
			x = 1900,
			y = 360,
			speed = 120,

			ShowTimer = false
			}
}