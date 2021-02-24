local Object = require 'lib.classic.classic'
local sodapop = require "lib/sodapop"

local Vector = require 'vector'
local PowerUp = require 'powerUp'
local Debris = require 'debris'
local Debris = require 'debris'
local DebrisEnemy = require 'debrisEnemy'
local SoftObject = Object:extend()

function SoftObject:new(x, y, variant)
  self.position = Vector(x, y)
  self.width = 15
  self.height = 15
  self.origin = Vector(0, -2)
  self.state = 1
  self.variant = variant
  self.sprite = sodapop.newAnimatedSprite(self:center():unpack())
  self.destroyed = false

    self.sprite:addAnimation('intact', {
		image        = love.graphics.newImage 'res/tiles/softObjects.png',
		frameWidth  = 15,
		frameHeight = 17,
		frames       = {
			{1, variant, 1, variant, .3},
		},
	})
	self.sprite:addAnimation('destroyed', {
		image       = love.graphics.newImage 'res/tiles/softObjects.png',
		frameWidth  = 15,
		frameHeight = 17,
		frames      = {
			{2, variant, 5, variant, .1},
		},
	})
end

function SoftObject:center()
	return self.position + Vector(self.width / 2, self.height / 2)
end

function SoftObject:update(dt)
	if self.destroyed then

	end
	self.sprite:update(dt)
end

function SoftObject:draw()
	if self.destroyed then
		return
	end
	self.sprite:draw(self.origin.x, self.origin.y)
end

function SoftObject:SpawnPowerUp()
	local chance = math.random()
	if chance < 0.25 then
		local powerUp = PowerUp(self.position.x , self.position.y , math.random(1,4))
		table.insert(objects, powerUp)
		world:add(powerUp, powerUp.position.x, powerUp.position.y, powerUp.width, powerUp.height)
	end
end

function SoftObject:DebrisDestruction()
	local debris = Debris(self.position.x, self.position.y)
	table.insert(objects, debris)
	
	player1Score = player1Score + 1
end

function SoftObject:DebrisEnemyDestruction()
	local debrisEnemy = DebrisEnemy(self.position.x, self.position.y)
	table.insert(objects, debrisEnemy)
	player2Score = player2Score + 1
end

return SoftObject
