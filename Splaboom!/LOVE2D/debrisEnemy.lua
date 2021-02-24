local Object = require 'lib.classic.classic'
local Vector = require 'vector'

local DebrisEnemy = Object:extend()

-- particle stuff --
function DebrisEnemy:new(x, y)
	self.position = Vector(x, y)
	self.width = 12
	self.height = 9

	self.image = love.graphics.newImage('res/sprites/debris_particlesb.png')

	self.quads = {}
	for j = 0, 3 do
		for i = 0, 6 do
			local quad = love.graphics.newQuad(i * 3, j * 6, 3, 6, self.image:getDimensions())
			table.insert(self.quads, quad)
		end
	end

	self.textures = {}
	for i = 1, 5 do
		local q = self.quads[math.random(1, #self.quads)]
		local c = love.graphics.newCanvas(3, 6)
		love.graphics.setCanvas(c)
		love.graphics.draw(self.image, q, 0, 0)
		love.graphics.setCanvas()
		local p = {
			texture = c,
			x = math.random(self.position.x, self.position.x + self.width),
			y = math.random(self.position.y, self.position.y + self.height),
			r = math.random() * math.pi,
		}
		table.insert(self.textures, p)
	end

end
   
function DebrisEnemy:update(dt)
end

function DebrisEnemy:draw()
	for _, p in ipairs(self.textures) do
		love.graphics.setColor(20, 0, 60, 100)
		love.graphics.draw(p.texture, p.x, p.y + 2, p.r)
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(p.texture, p.x, p.y, p.r)
		
		
	end
end

return DebrisEnemy
