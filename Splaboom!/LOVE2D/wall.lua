local Object = require 'lib.classic.classic'
local sodapop = require "lib/sodapop"

local Vector = require 'vector'

local Wall = Object:extend()

function Wall:new(x, y)
	self.position = Vector(x, y)
	self.width = 15
	self.height = 15
	world:add(self, self.position.x, self.position.y, self.width, self.height)
end

function Wall:update(dt)
end

function Wall:draw()
end

return Wall