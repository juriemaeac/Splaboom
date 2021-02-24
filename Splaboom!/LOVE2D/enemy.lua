local Object = require 'lib.classic.classic'
local anim8 = require 'lib.anim8'

local Vector = require 'vector'
local PowerUp = require 'powerUp'
local SoftObject = require 'softObject'
local Wall = require 'wall'
local Bomb = require 'bombEnemy'

local Enemy = Object:extend()

function Enemy:new(x, y)
	self.position = Vector(x, y)
	self.width = 12
	self.height = 12
	self.origin = Vector(2, 6)
	self.direction = Vector(0, 1)
	self.animation = 'idleDown'
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

function Enemy:center()
	return self.position + Vector(self.width / 2, self.height / 2)
end

function Enemy:updateAnimation(vector)
	if vector == Vector(-1, 0) then self.animation = 'walkLeft' end
	if vector == Vector(1, 0) then self.animation = 'walkRight' end
	if vector == Vector(0, 1) then self.animation = 'walkDown' end
	if vector == Vector(0, -1) then self.animation = 'walkUp' end
end

function Enemy:updateIdle(vector)
	if vector == Vector(-1, 0) then self.animation = 'idleLeft' end
	if vector == Vector(1, 0) then self.animation = 'idleRight' end
	if vector == Vector(0, 1) then self.animation = 'idleDown' end
	if vector == Vector(0, -1) then self.animation = 'idleUp' end
end

function isSafe(position)
	local tile = map:toTile(position)
	return safetyGrid[tile.y][tile.x] <= 0
end

function occupied(position, ...)
	local args = {...}
	local function filter(item)
		local result = false
		for _, objectType in ipairs(args) do
			if item:is(objectType) then
				result = true
				break
			end
		end
		return result
	end

	local items, len = world:queryRect(position.x, position.y, 15, 15, filter)
	return len ~= 0
end

function Enemy:findPath(target)
	local targetTile = map:toTile(target)
	local startTile = map:toTile(self.position)

	local closed = {}
	local open = {startTile}
	local nodes = {
		[tostring(startTile)] = {
			pos = startTile,
			gcost = 0,
			hcost = map:distance(startTile, targetTile),
			parent = nil,
		},
	}

	while open[1] ~= targetTile and #open > 0 do
		local pos = table.remove(open, 1)
		local current = nodes[tostring(pos)]
		closed[tostring(current.pos)] = true

		local neighbors = map:getNeighbors(pos:unpack())
		for _, neighbor in ipairs(neighbors) do
			-- ignoring bomb if neighbor position is the target position
			-- otherwise, would never be able to find the target position
			if neighbor == targetTile or not occupied(map:toWorld(neighbor), Wall, Bomb) then
				local cost = current.gcost + 1
				local node = nodes[tostring(neighbor)]
				local isClosed = closed[tostring(neighbor)]
				if node and cost < node.gcost then
					node.gcost = cost
					node.parent = current
				end
				if not node and not isClosed then
					table.insert(open, neighbor)
					nodes[tostring(neighbor)] = {
						pos = neighbor,
						gcost = cost,
						hcost = map:distance(neighbor, targetTile),
						parent = current,
					}
				end
			end
		end

		-- rank open nodes
		table.sort(open, function(a, b)
			local nodeA = nodes[tostring(a)]
			local nodeB = nodes[tostring(b)]
			return (nodeA.gcost + nodeA.hcost) < (nodeB.gcost + nodeB.hcost)
		end)
	end

	local path = {}
	local current = nodes[tostring(open[1])]
	if not current then
		return path
	end
	while current.parent ~= nil do
		table.insert(path, map:toWorld(current.pos))
		current = current.parent
	end
	return path
end

function Enemy:placeBomb()
	if self.usedBombs < self.maxBombs then
		local bomb = Bomb(self, self.position:unpack())
		table.insert(objects, bomb)
		self.usedBombs = self.usedBombs + 1
	end
end

function Enemy:findSafeTile()
	local tile = map:toTile(self.position)

	local seen = {}
	local queue = {tile}
	while #queue > 0 do
		local current = table.remove(queue, 1)
		seen[tostring(current)] = true

		if isSafe(map:toWorld(current)) then
			return map:toWorld(current)
		end

		local neighbors = map:getNeighbors(current:unpack())
		for _, neighbor in ipairs(neighbors) do
			local index = (neighbor.y - 1) * map.width + neighbor.x
			local isCollidable = map.collidables[index]
			if isCollidable == 0 then
				if not seen[tostring(neighbor)] and not occupied(map:toWorld(neighbor), Wall, Bomb, SoftObject) then
					table.insert(queue, neighbor)
				end
			end
		end
	end
end

function Enemy:update(dt)
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

	if love.keyboard.isDown('x') then
		if self.usedBombs < self.maxBombs then
			local bomb = Bomb(self, self.position:unpack())
			table.insert(objects, bomb)
			self.usedBombs = self.usedBombs + 1
		end
	end

	if velocity ~= Vector(0, 0) then
		local newPosition = self.position + velocity
		local actualX, actualY, cols, cols_len = world:move(self, newPosition.x, newPosition.y,
			function(item, other)
				local Player = require 'player'
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
			self:updateAnimation(self.direction)
		end
	else
		self:updateIdle(self.direction)
	end


	self.animations[self.animation]:update(dt)
end

function Enemy:draw()
	if self.target then
		love.graphics.rectangle('line', self.target.x, self.target.y, 15, 15)
	end
	self.animations[self.animation]:draw(
		self.sprite, self.position.x, self.position.y, 0, 1, 1, self.origin.x, self.origin.y
	)
end

return Enemy
