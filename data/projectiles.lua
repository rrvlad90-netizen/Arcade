--В require нельзя писать .lua. т.е. MeleeProjectile = require("data.projectiles.melee_projectile.lua") -ошибка!!!
return {
    FlyingShooterBullet = require("data.projectiles.flying_shooter_bullet"),
    BatBomberDrop = require("data.projectiles.bat_bomber_drop"),
	MeleeProjectile = require("data.projectiles.melee_projectile")
}