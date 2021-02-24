--[[local Bomb = require 'bomb'
local Vector = require 'vector'
local SoftObject = require 'softObject'

local Colored = Object:extend()

function Colored:new(x, y)
    self.position = Vector(x, y)
    self.width = 15
    self.height = 15
    
	coloredtile = love.graphics.newImage('res/sprites/debris_particles1.png')
	self.fuseDuration = 2
	self.explosionDuration = self.fuseDuration + 0.6
	self.timer = 0
	self.radius = player.bombRadius
	self.underPlayer = true

end

function Colored:draw()
	x =	x + math.random(-3, 3)
		y =	y + math.random(-3, 3)
		
		frameWidth = 40
		frameHeight = 40
		frames = {
			{1, 1, 16, 1, .04}
		}
end

return Colored
]]