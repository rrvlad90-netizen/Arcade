local AnimationSet = require("animation_set")

local EnemyBullet = {}
EnemyBullet.__index = EnemyBullet

local function fileExists(path)
    return path and love.filesystem.getInfo(path) ~= nil
end

-----для анимаций
local function createAnimationConfig(config)
    if config.animations then
        return {
            w = config.w,
            h = config.h,
            color = config.color,
            defaultState = config.defaultState or "idle",
            animations = config.animations
        }
    end

    local frames = config.frames

    if not frames and config.image then
        frames = {
            {
                image = config.image
            }
        }
    end

    return {
        w = config.w,
        h = config.h,
        color = config.color,
        defaultState = "idle",
        animations = {
            idle = {
                loop = config.loop == true,
                holdLastFrame = config.holdLastFrame == true,
                frameDuration = config.frameDuration or 0.08,
                frames = frames or {}
            }
        }
    }
end

function EnemyBullet:new(config)
    local bullet = setmetatable({}, EnemyBullet)

    bullet.x = config.x or 0
    bullet.y = config.y or 0
    bullet.w = config.w or 12
    bullet.h = config.h or 12


	bullet.vx = config.vx or -220 --снаряд летит по прямой
    bullet.vy = config.vy or 0---снаряд падает с неба

    -- Гравитация projectile.
    -- Если 0, летит по прямой.
    -- Если больше 0, projectile летит по дуге и падает вниз.
    bullet.gravity = config.gravity
        or config.projectileGravity
        or config.projectile_gravity
        or 0

    -- Если true, картинка будет поворачиваться по направлению полёта.
    -- Удобно для стрелы.
    bullet.rotateToVelocity = config.rotateToVelocity == true
        or config.rotate_to_velocity == true

    bullet.rotation = config.rotation or 0

    bullet.damage = config.damage or 1

	-- Эффект при попадании/ударе.
	bullet.impactEffect = config.impactEffect
		or config.impact_effect

	bullet.impactOffsetX = config.impactOffsetX
		or config.impact_offset_x
		or 0

	bullet.impactOffsetY = config.impactOffsetY
		or config.impact_offset_y
		or 0

	-- Если true, projectile проверяет удар о землю.
	bullet.collideGround = config.collideGround == true
		or config.collide_ground == true

	-- Если true, projectile проверяет удар о solid-платформы/возвышенности.
	bullet.collidePlatforms = config.collidePlatforms == true
		or config.collide_platforms == true

    bullet.imagePath = config.image
    bullet.image = nil

    if fileExists(bullet.imagePath) then
        bullet.image = love.graphics.newImage(bullet.imagePath)
    end

    bullet.color = config.color or {1.0, 0.25, 0.2}



	--Если есть animations/frames — projectile будет анимированным.
		bullet.animationSet = nil

		if config.animations or config.frames then
			bullet.animationSet = AnimationSet:new(createAnimationConfig({
				w = bullet.w,
				h = bullet.h,
				color = bullet.color,

				image = config.image,
				frames = config.frames,
				animations = config.animations,

				loop = config.loop,
				holdLastFrame = config.holdLastFrame,
				frameDuration = config.frameDuration,
				defaultState = config.defaultState
			}))
		end


	bullet.alpha = config.alpha--прозрачность

	if bullet.alpha == nil then
		bullet.alpha = 1
	end

	bullet.dissapearbytime = config.dissapearbytime
		or config.disappearByTime
		or config.disappear_by_time
		or 0

	bullet.age = 0
	bullet.dead = false

    return bullet
end

function EnemyBullet:update(dt)
    if self.dead then
        return
    end

    self.age = self.age + dt

	self.vy = self.vy + self.gravity * dt

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
--анимация	
	if self.animationSet then
			self.animationSet:update(dt)
		end	

    if self.rotateToVelocity
        and (self.vx ~= 0 or self.vy ~= 0)
    then
        local atan2 = math.atan2 or math.atan
        self.rotation = atan2(self.vy, self.vx)
    end

    if self.dissapearbytime > 0
        and self.age >= self.dissapearbytime
    then
        self.dead = true
    end
end

function EnemyBullet:isOffscreen()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    return self.x + self.w < -100
        or self.x > screenWidth + 100
        or self.y + self.h < -100
        or self.y > screenHeight + 100
end
--исчезает через время (для melee атаки)
function EnemyBullet:isRemovable()
    return self.dead or self:isOffscreen()
end

function EnemyBullet:getHitbox()
    return {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

function EnemyBullet:draw()
---аниммация
	if self.animationSet then
			local animation = self.animationSet:getCurrentAnimation()
			local image = nil

			if animation then
				image = animation:getCurrentImage()
			end

			if image then
				local scaleX = self.w / image:getWidth()
				local scaleY = self.h / image:getHeight()

				if self.rotateToVelocity then
					self.animationSet:draw(
						self.x + self.w / 2,
						self.y + self.h / 2,
						self.rotation,
						scaleX,
						scaleY,
						image:getWidth() / 2,
						image:getHeight() / 2,
						self.alpha
					)
				else
					self.animationSet:draw(
						self.x,
						self.y,
						0,
						scaleX,
						scaleY,
						0,
						0,
						self.alpha
					)
				end

				return
			end
		end


    if self.image then
		love.graphics.setColor(1, 1, 1, self.alpha)
---Старый блок без учета полета по дуге	
 --       love.graphics.draw(
 --           self.image,
 --           self.x,
 --           self.y,
 --           0,
 --           self.w / self.image:getWidth(),
 --           self.h / self.image:getHeight()
 --       )
 ---Добавили полет по дуге
		local scaleX = self.w / self.image:getWidth()
        local scaleY = self.h / self.image:getHeight()

        if self.rotateToVelocity then
            love.graphics.draw(
                self.image,
                self.x + self.w / 2,
                self.y + self.h / 2,
                self.rotation,
                scaleX,
                scaleY,
                self.image:getWidth() / 2,
                self.image:getHeight() / 2
            )
        else
            love.graphics.draw(
                self.image,
                self.x,
                self.y,
                0,
                scaleX,
                scaleY
            )
        end

        return
    end
--мокап
	love.graphics.setColor(
		self.color[1],
		self.color[2],
		self.color[3],
		self.alpha
	)
    love.graphics.circle("fill", self.x + self.w / 2, self.y + self.h / 2, self.w / 2)

	love.graphics.setColor(0.25, 0.05, 0.04, self.alpha)
    love.graphics.circle("line", self.x + self.w / 2, self.y + self.h / 2, self.w / 2)
end

love.graphics.setColor(1, 1, 1)

return EnemyBullet