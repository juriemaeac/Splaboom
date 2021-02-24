local Object = require 'lib.classic.classic'
local sodapop = require "lib/sodapop"
local Vector = require 'vector'

local PowerUp = Object:extend()

local effects = {
	-- bomb
	function(enemy)
		enemy.maxBombs = player.maxBombs + 1
	end,
	-- fire potion
	function(enemy)
		enemy.bombRadius = player.bombRadius + 1
	end,
	-- boots
	function(enemy)
		enemy.speed = player.speed + 15
	end,
	-- glove
	function(enemy)
		if player.speed > 30 then
			player.speed = player.speed - 15
		else
			return
		end
	end,
}

function PowerUp:new(x, y, variant)
  self.position = Vector(x, y)
  self.width = 15
  self.height = 15
  self.origin = Vector(0, -2)
  self.variant = variant
  self.sprite = sodapop.newAnimatedSprite(self:center():unpack())
  self.burned = false

	-- set function define effect on player
	self.addEffect = effects[variant]

  self.sprite:addAnimation('intact', {
		image        = love.graphics.newImage 'res/sprites/powerUps.png',
		frameWidth  = 15,
		frameHeight = 16,
		frames       = {
			{variant, 1, variant, 1, .3},
		},
	})
	self.sprite:addAnimation('burned', {
		image       = love.graphics.newImage 'res/sprites/powerUps.png',
		frameWidth  = 15,
		frameHeight = 16,
		frames      = {
			{2, variant, 5, variant, .1},
		},
	})
end

function PowerUp:center()
	return self.position + Vector(self.width / 2, self.height / 2)
end

function PowerUp:update(dt)
	if self.burned then

		return
	end
	self.sprite:update(dt)
end

function PowerUp:draw()
	if self.burned then
		return
	end
	self.sprite:draw(self.origin.x, self.origin.y)
end

return PowerUp
