--В require нельзя писать .lua. т.е. MeleeProjectile = require("data.projectiles.melee_projectile.lua") -ошибка!!!
return {
    FlyingShooterBullet = require("data.projectiles.flying_shooter_bullet"),
    BatBomberDrop = require("data.projectiles.bat_bomber_drop"),
	ArcArrow = require("data.projectiles.arc_arrow"),
	EnemyFireball = require("data.projectiles.enemyfireball"),
	DiagonalDownProjectile = require("data/projectiles/diagonal_down_projectile"),
	AimedProjectile = require("data.projectiles.aimed_projectile"),	--самонаводящийся
	
	CompanionMeleeProjectile = require("data.projectiles.companion_melee_projectile"), --npc проджектайл	

		
--Вблизи
	MeleeProjectile = require("data.projectiles.melee_projectile")
}