local Object = require 'lib.classic.classic'
local sodapop = require "lib/sodapop"

local Vector = require 'vector'

local Map = Object:extend()

floorTiles = {}

function Map:new(datafile)
	data = require(datafile)

  self.width = 19
  self.height = 13
	self.tilewidth = 15
	self.tileheight = 15

	self.background = data.background
	self.tileset = data.tileset
	self.walls = data.walls
	self.floors = data.floors
	self.collidables = data.collidables
	self.tiles = data.tiles

	-- make random floor pattern
	self:generateFloorTiles()

	self.floor = love.graphics.newCanvas(self.width * 15, self.height * 15)
	-- prerender floor
	love.graphics.setCanvas(self.floor)
	self:foreach(function(x, y, value)
		local x = x - 1
		local y = y - 1
		love.graphics.draw(self.tileset, self.floors[self:getFloorTiles(x,y)], x * 15, y * 15)
	end)
	love.graphics.setCanvas()
end

function Map:numNeighbors(x, y)
	local num = 4
	if x == 1 or x == self.width then
		num = num - 1
	end
	if y == 1 or y == self.height then
		num = num - 1
	end
	return num
end

function Map:getNeighbors(x, y)
	local neighbors = {}
	if x ~= 1 then
		table.insert(neighbors, Vector(x - 1, y))
	end
	if y ~= 1 then
		table.insert(neighbors, Vector(x, y - 1))
	end
	if x ~= self.width then
		table.insert(neighbors, Vector(x + 1, y))
	end
	if y ~= self.height then
		table.insert(neighbors, Vector(x, y + 1))
	end
	return neighbors
end

function Map:isSpawnLocation(x, y)
	if (x == 2 or x == self.width - 1) and (y == 2 or y == self.height - 1) then
		return true
	end
	if (x == 2 or x == self.width - 1) and (y == 3 or y == self.height - 2) then
		return true
	end
	if (y == 2 or y == self.height - 1) and (x == 3 or x == self.width - 2) then
		return true
	end
	return false
end

function Map:toTile(position)
	local x = position.x
	local y = position.y
	x = math.floor(x / 15) + 1
	y = math.floor(y / 15) + 1
	return Vector(x, y)
end

function Map:toWorld(tile)
	local x = tile.x - 1
	local y = tile.y - 1
	return Vector(x * 15, y * 15)
end

function Map:distance(tile, targetTile)
	local distanceX = math.abs(tile.x - targetTile.x)
	local distanceY = math.abs(tile.y - targetTile.y)
	return distanceX + distanceY
end

function Map:foreach(fn)
	for row = 1, self.height do
		for col = 1, self.width do
			local index = (row - 1) * self.width + col
			fn(col, row, self.tiles[index], self.collidables[index])
		end
	end
end

function Map:generateFloorTiles()
	-- create randomized tiles
	math.randomseed( os.time() )
	for i=1, self.width do
		for j=1, self.height do
			local chosenTile = math.random(1,4)
			table.insert(floorTiles, chosenTile)
		end
	end
end

function Map:getFloorTiles(x,y)
	local tileNumber = (y * self.width) + x + 1
	return floorTiles[tileNumber]
end

function Map:update(dt)
end

function Map:drawFloor(x, y)
	love.graphics.draw(self.floor, x, y)
end

function Map:drawWalls()
	self:foreach(function(x, y, tile)
		local x = x - 1
		local y = y - 1
		if tile ~= 0 then
			love.graphics.draw(self.tileset, self.walls[tile], x * 15, y * 15 - 2)
		end
	end)
end

return Map
