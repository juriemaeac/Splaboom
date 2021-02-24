local Object = require 'lib.classic.classic'
local sodapop = require "lib/sodapop"
local screen = require "lib/shack/shack"
local Vector = require 'vector'
local SoftObject = require 'softObject'

local Bomb = Object:extend()

function Bomb:new(enemy, x, y)
	self.enemy = enemy
  	self.position = Vector(x, y)
  	self.width = 15
  	self.height = 15
  	self.origin = Vector(0, -2)

	self.fuseDuration = 2.3
	self.explosionDuration = self.fuseDuration + 0.6
	self.timer = 0
	self.exploded = false
	self.explosionTimer = 0
	self.radius = enemy.bombRadius
	self.underEnemy = true

	self.explosions = {}

	self.sprite = sodapop.newAnimatedSprite(self:center():unpack())

	self.sprite:addAnimation('idle', {
		image	= love.graphics.newImage('res/sprites/bomb_blue.png'),
		frameWidth = 15,
		frameHeight = 15,
		frames = {
			{1, 1, 4, 1, .2},
		},
	})

	world:add(self, self.position.x, self.position.y, self.width, self.height)

	self.affectedTiles, _ = self:checkTiles()
	for _, tile in ipairs(self.affectedTiles) do
		safetyGrid[tile.y][tile.x] = safetyGrid[tile.y][tile.x] + 1
	end
end

function Bomb:center()
	return self.position + Vector(self.width / 2, self.height / 2)
end

function Bomb:update(dt)
	if self.underEnemy then
		local colliding = false
		local items, _ = world:queryRect(self.position.x, self.position.y, self.width, self.height)
		for _, item in ipairs(items) do
			if item == self.Enemy then
				colliding = true
			end
		end
		if not colliding then
			self.underEnemy = false
		end
	end

	if self.exploded then
		for _, explosionSprite in ipairs(self.explosions) do
			explosionSprite:update(dt)
			if not explosionSprite.playing and self.explosionTimer > explosionSprite.delay then
				explosionSprite.playing = true
				audio.explosion:stop()
				audio.explosion:play()
			end
		end
		self.explosionTimer = self.explosionTimer + dt
		return
	end

	if self.timer > self.fuseDuration then
		self:check(self.position.x, self.position.y)
		self:addExplosion(self.position.x + 7, self.position.y + 7, 0)
		local directions = {
			[Vector(0, 1)] = true,
			[Vector(0, -1)] = true,
			[Vector(1, 0)] = true,
			[Vector(-1, 0)] = true
		}
		for i = 1, self.radius do
			for direction, spreading in pairs(directions) do
				if spreading then
					local tile = self.position + (direction * i * 15)
					local hit = self:check(tile.x, tile.y)
					if hit then
						directions[direction] = false
						if hit == 2 then
							self:addExplosion(tile.x + 7, tile.y + 7, i / 20)
							
						end
					else
						self:addExplosion(tile.x + 7, tile.y + 7, i / 20)
						
					end
				end
			end
		end
		self.exploded = true
		world:remove(self)

		for _, tile in ipairs(self.affectedTiles) do
			safetyGrid[tile.y][tile.x] = safetyGrid[tile.y][tile.x] - 1
		end

		if self.timer < self.explosionDuration then
			screen:setShake(10)
		end
		self.enemy.usedBombs = self.enemy.usedBombs - 1
	end

	self.sprite:update(dt)
	self.timer = self.timer + dt
end

function Bomb:draw()
	if self.exploded == false then
		self.sprite:draw(self.origin.x, self.origin.y)
	else
		for _, explosionSprite in ipairs(self.explosions) do
			if explosionSprite.playing then
				explosionSprite:draw()
			end
		end
	end
end

function Bomb:check(x, y)
	local Enemy = require 'enemy'
	local Player = require 'player'
	local Wall = require 'wall'
	local hit = nil
	local items, _ = world:queryRect(x, y, self.width, self.height)
	
	for _, item in ipairs(items) do
		if item:is(Wall) then
			hit = 1
		elseif item:is(SoftObject) then
			item.destroyed = true
			item:SpawnPowerUp()
			item:DebrisEnemyDestruction()
			
			world:remove(item)
			hit = 2
		elseif item:is(Player) or item:is(Enemy) then
			item.remove = false
		end
	end
	return hit
end

function Bomb:checkTiles()
	local Enemy = require 'enemy'
	local Player = require 'player'
	local Wall = require 'wall'
	local collisions = {}
	local tiles = {map:toTile(self.position)}
	local directions = {Vector(0, 1), Vector(0, -1), Vector(1, 0), Vector(-1, 0)}

	local items, _ = world:queryRect(self.position.x, self.position.y, self.width, self.height)
	for _, item in ipairs(items) do
		if item:is(Wall) or item:is(SoftObject) or item:is(Player) or item:is(Enemy) then
			table.insert(collisions, item)
			break
		end
	end

	for _, dir in ipairs(directions) do
		for i = 1, self.radius do
			local hit = false
			local tile = self.position + (dir * i * 15)
			local items, _ = world:queryRect(tile.x, tile.y, self.width, self.height)
			for _, item in ipairs(items) do
				if item:is(Wall) or item:is(SoftObject) or item:is(Player) or item:is(Enemy) then
					table.insert(collisions, item)
					hit = true
				end
			end
			table.insert(tiles, map:toTile(tile))
			if hit then break end
		end
	end
	return tiles, collisions
end

function Bomb:addExplosion(x, y, delay)
	local explosionSprite = sodapop.newAnimatedSprite(
			x + math.random(-3, 3),
			y + math.random(-3, 3)
		)
	
	explosionSprite:addAnimation('explode1', {
		image	= love.graphics.newImage('res/sprites/explosion_blue.png'),
		
		frameWidth = 47,
		frameHeight = 39,
		frames = {
			{1, 1, 16, 1, .04},
		},
		stopAtEnd    = true
	})
	
	playing = math.random(0, 1)
	explosionSprite.delay = delay
	explosionSprite.playing = false
	table.insert(self.explosions, explosionSprite)
end

return Bomb
