local Object = require 'lib.classic.classic'
local anim8 = require 'lib.anim8'

local Vector = require 'vector'
local PowerUp = require 'powerUp'
local SoftObject = require 'softObject'
local Wall = require 'wall'
local Bomb = require 'bomb'

local Opponent = Object:extend()

function Opponent:new(x, y)
	self.position = Vector(x, y)
	self.width = 15
	self.height = 15
	self.origin = Vector(2, 6)
	self.direction = Vector(0, 1)
	self.speed = 40
	self.target = self.position
	self.maxBombs = 1
	self.usedBombs = 0
	self.bombRadius = 1
	self.powerUps = {}
	self.sprite = love.graphics.newImage('res/sprites/player_sprites.png')
	self.grid = anim8.newGrid(15, 19, self.sprite:getWidth(), self.sprite:getHeight())
	self.animations = {
		walkUp = anim8.newAnimation(self.grid('1-3', 1), 0.1),
		walkDown = anim8.newAnimation(self.grid('1-3', 2), 0.1),
		walkRight = anim8.newAnimation(self.grid('1-3', 3), 0.1),
		walkLeft = anim8.newAnimation(self.grid('1-3', 3), 0.1):flipH(),
		idleUp = anim8.newAnimation(self.grid(1, 1), 0.1),
		idleDown = anim8.newAnimation(self.grid(1, 2), 0.1),
		idleRight = anim8.newAnimation(self.grid(1, 3), 0.1),
		idleLeft = anim8.newAnimation(self.grid(1, 3), 0.1):flipH(),
	
	}
	world:add(self, self.position.x, self.position.y, self.width, self.height)
end

function Opponent:center()
	return self.position + Vector(self.width / 2, self.height / 2)
end

function Opponent:updateAnimation(vector)
	if vector == Vector(-1, 0) then self.animation = 'walkLeft' end
	if vector == Vector(1, 0) then self.animation = 'walkRight' end
	if vector == Vector(0, 1) then self.animation = 'walkDown' end
	if vector == Vector(0, -1) then self.animation = 'walkUp' end
end

function Opponent:updateIdle(vector)
	if vector == Vector(-1, 0) then self.animation = 'idleLeft' end
	if vector == Vector(1, 0) then self.animation = 'idleRight' end
	if vector == Vector(0, 1) then self.animation = 'idleDown' end
	if vector == Vector(0, -1) then self.animation = 'idleUp' end
end



function Opponent:update(dt)
	self.onBomb = nil
	local items, len = world:queryRect(self.position.x, self.position.y, self.width, self.height)
	for _, item in ipairs(items) do
		if item:is(Bomb) then
			self.onBomb = item
		end
	end

	local velocity = Vector(0, 0)

	if love.keyboard.isDown('d') then
		velocity.x = self.speed * dt
	elseif love.keyboard.isDown('a') then
		velocity.x = -self.speed * dt
	end

	if love.keyboard.isDown('s') then
		velocity.y = self.speed * dt
	elseif love.keyboard.isDown('w') then
		velocity.y = -self.speed * dt
	end

	if velocity ~= Vector(0, 0) then
		local newPosition = self.position + velocity
		local actualX, actualY, cols, cols_len = world:move(self, newPosition.x, newPosition.y,
			function(item, other)
				local Enemy = require 'enemy'
				if other:is(PowerUp) then
					return 'cross'
				elseif other:is(Bomb) and self.onBomb == other then
					return 'cross'
				elseif other:is(Player) or other:is(Enemy) then
					return 'cross'
				else
					return 'slide'
				end
			end
		)
		self.position = Vector(actualX, actualY)

		-- handle collisions
		for _, col in ipairs(cols) do
			local other = col.other
			if other.is and other:is(PowerUp) then
				other.remove = true
				audio.collectPowerUp:stop()
				audio.collectPowerUp:play()
				if not self.powerUps[other] then
					self.powerUps[other] = other
					other.addEffect(self)
				end
			end
		end

		-- animation control
		local normalized = velocity:normalize()
		if normalized ~= self.direction then
			self.direction = velocity:normalize()
			updateAnimation(self.direction)
		end
	else
		updateIdle(self.direction)
	end

	self.animations[self.animation]:update(dt)
end

function Opponent:draw()
	if self.target then
		love.graphics.rectangle('line', self.target.x, self.target.y, 15, 15)
	end
	self.animations[self.animation]:draw(
		self.sprite, self.position.x, self.position.y, 0, 1, 1, self.origin.x, self.origin.y
	)
end

return Opponent
