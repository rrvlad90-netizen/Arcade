--В require нельзя писать .lua. т.е. MeleeProjectile = require("data.projectiles.melee_projectile.lua") -ошибка!!!
return {
    FlyingShooterBullet = require("data.projectiles.flying_shooter_bullet"),
    BatBomberDrop = require("data.projectiles.bat_bomber_drop"),
	ArcArrow = require("data.projectiles.arc_arrow"),
	EnemyFireball = require("data.projectiles.enemyfireball"),
		
--Вблизи
	MeleeProjectile = require("data.projectiles.melee_projectile")
}