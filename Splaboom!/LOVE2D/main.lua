local bump = require "lib/bump"
local screen = require "lib/shack/shack"
local Vector = require 'vector'
local Player = require 'player'
local Enemy = require 'enemy'
local Bomb = require 'bomb'
local SoftObject = require 'softObject'
local Wall = require 'wall'
local Map = require 'map'
local cron = require 'cron'

--TEST 10 SECS
local seconds = 180 --time limit
local msg = " "
local timer = cron.every(1, function() seconds = seconds - 1 end)
--after 180 secs saka lalabas
--TEST 10SECS
local atimer = cron.after(180, function() game_over() end) 
--local logotimer = cron.after(2, function() image = false end) 
--return newClock(time, callback, updateAfterClock, ...)
--local menutimer = cron.after(3, function() change:menu() end)
love.graphics.setDefaultFilter("nearest", "nearest")

local game_state = 'menu'
local menus = { 'Play', 'New Game', 'How To Play', 'Quit'  }
local selected_menu_item = 1

-- functions
local draw_menu
local menu_keypressed
local draw_how_to_play
local how_to_play_keypressed
local draw_game
local game_keypressed

audio = {
	battleMusic = love.audio.newSource('res/audio/music/background.mp3', 'stream'),
	explosion = love.audio.newSource('res/audio/sfx/Explosion1.wav', 'static'),
	collectPowerUp = love.audio.newSource('res/audio/sfx/collectPowerUp.wav', 'static'),
	clock = love.audio.newSource('res/audio/music/clock.wav', 'static'),
	gameOver = love.audio.newSource('res/audio/sfx/gameOver.mp3', 'static'),
}

debug = false

--FOR INTRO
introtimer = 0
--menutimer = 0

fadein  = 2
display = 2
fadeout = 2
imgTeam = love.graphics.newImage("res/tiles/teamLogo.png")
image = love.graphics.newImage("res/tiles/logo1.png")
how = love.graphics.newImage("res/tiles/how.png")
over = love.graphics.newImage("res/tiles/over.png")

function love.load() ----------------------------------------------------------------------------------------
	player1Score = 0
    player2Score = 0
	winningPlayer = 0
	--AIplayerScore = 0
    
	-- get the width and height of the game window in order to center menu items
	window_width, window_height = love.graphics.getDimensions()

	-- use a big font for the menu
	local font = love.graphics.setNewFont(150)
	local font1 = love.graphics.setNewFont(60)
  
	-- get the height of the font to help calculate vertical positions of menu items
	font_height = font:getHeight()
	-------------------------------------------------------------------------------------------
	
	world = bump.newWorld()

	--background and tiles
	map = Map('dungeon')
	safetyGrid = {}
	for y = 1, map.height do
		safetyGrid[y] = {}
		for x = 1, map.width do
			safetyGrid[y][x] = 0
		end
	end
	
	player = Player(15, 15)
	world:add(player, player.position.x, player.position.y, player.width, player.height)
	
	--FOR ADDITIONAL PLAYER 
	enemy2 = Enemy(15 * 17, 15 * 11) --lower right ung location (pwede pang AI)
	--enemy2 = Enemy(15 * 17, 15)
	--enemy3 = Enemy(15, 15 * 11) lower left ung location (pwede pang AI)
	--objects = {player, enemy1, enemy2, enemy3}
	objects = {player, enemy2}

	------FOR GENERATING WHOLE SPRITES IN GAME STATE-----------------------------------------------------------------------------------------
	map:foreach(function(x, y, tile, collidable)
		local chance = math.random()
		if collidable == 0 and not map:isSpawnLocation(x, y) and chance < 0.7 then
			local softObject = SoftObject((x - 1) * 15, (y - 1) * 15, math.random(1,5))
			table.insert(objects, softObject)
			world:add(softObject, softObject.position.x, softObject.position.y, softObject.width, softObject.height)
		elseif collidable == 1 then
			local x = x - 1
			local y = y - 1
			local wall = Wall(x * 15, y * 15)
			table.insert(objects, wall)
		end
	end)
	
	------------------------------------------------------------------------------------------------------------------------
	--whole game size
	scale = 3.3
	background = love.graphics.newCanvas(width, height)
	arena = love.graphics.newCanvas(map.width * map.tilewidth, map.height * map.tileheight)

	--background music loop
	audio.battleMusic:play()
	audio.battleMusic:setLooping(true)

	--timer and score font and size
	love.graphics.setDefaultFilter('nearest', 'nearest')
	smallFont = love.graphics.newFont('font.ttf', 30)
	xsmallFont = love.graphics.newFont('font.ttf', 20)
	
end

function love.update(dt) --------------------------------------------------------------------------------------------------
	--INTRO FADE IN AND OUT
	introtimer=introtimer+dt

	if introtimer<fadein then 
		alpha=2
		
	elseif introtimer<display then 
		alpha=3
		
	elseif introtimer<fadeout then 
		alpha=2
		
	else 
		alpha=0 
	end

	if game_state == 'game' then
		
		-- update everything in the game
		
		map:update(dt)
		screen:update(dt)
		
		for _, object in ipairs(objects) do
		object:update(dt)
		end
		
		local toRemove = {}
		for i, object in ipairs(objects) do
			if object.remove then
				table.insert(toRemove, i)
				world:remove(object)
				
				--player1Score = player1Score + 1 --dumadagdag ung score kapag nakakakuha ng power-ups
			end
		end
		
		for i = #toRemove, 1, -1 do
			local index = toRemove[i]
			table.remove(objects, index)
			--player2Score = player2Score + 1 --dumadagdag ung score kapag nakakakuha ng power-ups
		end
		timer:update(dt)
		atimer:update(dt)
		
	end
	
end

function love.draw() ----------------------------------------------------------------------------------------
	
	
	--INTRO LOGO
	--love.graphics.setColor(255, 255, 255, light)
	--love.graphics.setColor(255, 1, 255, alpha*255)
	love.graphics.setColor(255, 1, 255, 255)
	--love.graphics.draw(image, 10, -150)
	--FOR MENU
	--love.graphics.setColor(255, 1, 255, alpha*255)
	menu()
	
end

function teamLogo()
	love.graphics.setColor(255, 1, 255, alpha*255)
	love.graphics.draw(imgTeam,0,0)
	
end
function menu()
	if game_state == 'menu' then

		draw_menu()
		teamLogo()
		
	elseif game_state == 'how-to-play' then
		draw_how_to_play()

	elseif seconds <= 0 then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(over, 0, 0)
			--Font = love.graphics.newFont('font/splaboom.ttf', 120)
			Font0 = love.graphics.newFont('font/splaboom.ttf', 120)
			Font1 = love.graphics.newFont('font.ttf', 70)
			Font2 = love.graphics.newFont('font.ttf', 25)
			
			love.graphics.setFont(Font0)
			love.graphics.printf("Game Over!", 20, 250, window_width, 'center')
			if player1Score > player2Score then
				love.graphics.setFont(Font1)
				love.graphics.printf('Player 1 Wins!', 20, 450, window_width, 'center')
			elseif player1Score < player2Score then
				love.graphics.setFont(Font1)
				love.graphics.printf('Player 2 Wins!', 20, 450, window_width, 'center')
			else
				love.graphics.setFont(Font1)
				love.graphics.printf('DRAW!', 20, 450, window_width, 'center')
			end

			love.graphics.setFont(Font2)
			love.graphics.printf("Press Esc to go in Main Menu", 20, 605, window_width, 'center')

			audio.battleMusic:stop()
			audio.gameOver:play()
			audio.gameOver:setLooping(false)
			
	else -- game_state == 'game'
		
		draw_game()
		
		love.graphics.setFont(smallFont)
		--need pa ayusin timer, nag nenegative
		--kapag nag 0 times up then game over lalabas na ung winner
		love.graphics.print("Timer: "..seconds, 50, 10) 
		--score
		--no score pa wala pang colored tiles
		love.graphics.setFont(smallFont)
		love.graphics.print('Player1 Score: ' .. tostring(player1Score), 300, 10) 
		love.graphics.print('Player2 Score: ' .. tostring(player2Score), 700, 10) 

		-- y-sort objects
		--kapag pinindot tab while in playing lalabas ung gridlines and fps
		table.sort(objects, function(a, b)
			return a.position.y + a.height < b.position.y + b.height
		end)
		love.graphics.setCanvas(arena)
		love.graphics.clear()
		map:drawWalls(0, 0)
		
		if debug then
			for _, item in ipairs(world:getItems()) do
				local x, y, w, h = world:getRect(item)
				love.graphics.rectangle('line', x, y, w, h)
			end
			love.graphics.print('FPS: ' .. love.timer.getFPS())
		end
		for _, object in ipairs(objects) do
			object:draw()
			
		end
		love.graphics.setCanvas(background)
		
		--floor
		--map:drawFloor(68 - 15, 34 - 15)
		
		--love.graphics.draw(map.background)
		love.graphics.setCanvas()

		screen:apply()
		love.graphics.push()
		love.graphics.scale(scale)
		--background (width, height)
		--love.graphics.draw(background, 15, 15, 0, 1, 1, 0, 0)
		--crates (width, height)
		love.graphics.draw(arena, 67 - 15, 34 - 15, 0, 1, 1, 0, 0)
		love.graphics.pop()
		
	end

end

-- LOAD FOR MENU
function draw_menu()
	love.graphics.draw(image, 0, 0)
	local horizontal_center = window_width / 2 
	local vertical_center = window_height / 2 
	local start_y = vertical_center - (font_height * (#menus / 2))
	
	Font = love.graphics.newFont('font/splaboom.ttf', 130)
	Font1 = love.graphics.newFont('font.ttf', 50)
	-- draw guides to help check if menu items are centered, can remove later
	-- love.graphics.setColor(1, 1, 1, 0.1)
	-- love.graphics.line(horizontal_center, 0, horizontal_center, window_height)
	-- love.graphics.line(0, vertical_center, window_width, vertical_center)
  
	-- draw game title
	love.graphics.setColor(1, 1, 1, 1)

	--love.graphics.draw(blank, 0, 0)
	love.graphics.setFont(Font)
	--love.graphics.printf("SPLABOOM!", 0, 150, window_width, 'center')
  
	-- draw menu items
	for i = 1, #menus do
  
	  -- currently selected menu item is yellow
	  if i == selected_menu_item then
		love.graphics.setColor(1, 1, 0, 1)
  
	  -- other menu items are white
	  else
		love.graphics.setColor(1, 1, 1, 1)
	  end
  
	  -- draw this menu item centered
	  love.graphics.setFont(Font1)
	  love.graphics.printf(menus[i], 22, 80 * (i-1) + 330, window_width, 'center')
	end
  end
  
function draw_how_to_play()
  
	--[[love.graphics.printf(
	  "this is the 'how-to-play' state, press Esc to go back to the 'menu' state",
	  0,
	  window_height / 2 - font_height / 2,
	  window_width,
	  'center')  ]]
	love.graphics.draw(how, 0,0)
	Font0 = love.graphics.newFont('font/splaboom.ttf', 30)
	Font1 = love.graphics.newFont('font.ttf', 25)
	love.graphics.setFont(Font0)
	love.graphics.printf("Control Keys for Player 1:\n", 25, 290, window_width, 'center')
	love.graphics.printf("Control Keys for Player 2:\n", 25, 425, window_width, 'center')
	love.graphics.setFont(Font1)
	love.graphics.printf("UP, DOWN, LEFT, RIGHT ARROW KEYS\nUse SPACE BAR to drop a bomb\n\n", 25, 345, window_width, 'center')
	love.graphics.printf("W, S, A, D KEYS\nUse X to drop a bomb", 25, 485, window_width, 'center')
	love.graphics.printf("Press ESC to go back", 25, 600, window_width, 'center')
	 
	-- TODO: implement this function
  
end
  
function draw_game()
	
	love.graphics.setCanvas(arena)
	love.graphics.clear()
	map:drawWalls(0, 0)
	for _, object in ipairs(objects) do
		object:draw()
	end

	love.graphics.setCanvas(background)

	love.graphics.draw(map.background)
	love.graphics.setCanvas()

	screen:apply()
	love.graphics.push()
	love.graphics.scale(scale)
	--background (width, height)
	love.graphics.draw(background, -130, 15, 0, 1, 1, 0, 0)
	--crates (width, height)
	--love.graphics.draw(arena, 67 - 15, 34 - 15, 0, 1, 1, 0, 0)
	love.graphics.pop()
	
end


--KEYS USED IN GAME STATE
function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	elseif key == 'tab' then
		debug = not debug
	elseif key == 'space' then
		if player.usedBombs < player.maxBombs then
			local tile = map:toWorld(map:toTile(player.position + Vector(6, 4)))
			local occupied = false
			local items, _ = world:queryRect(tile.x, tile.y, 15, 15)
			for _, item in ipairs(items) do
				if item:is(Bomb) then
					occupied = true
					
				end
			end
			if not occupied then
				local bomb = Bomb(player, tile.x, tile.y)
				table.insert(objects, bomb)
				player.usedBombs = player.usedBombs + 1
				
			end
		end
	end
end

-- GAME OVER FUNCTION
function game_over()
	--love.graphics.clear()
	--love.graphics.setColor(1, 1, 1, alpha*1)
	love.graphics.draw(over, 0, 0)
	Font = love.graphics.newFont('font/splaboom.ttf', 130)
	love.graphics.setFont(Font)
	love.graphics.printf("SPLABOOM!", 0, 150, window_width, 'center')
	love.graphics.printf("GAME OVER!", 0, 150, window_width, 'center')
	audio.battleMusic:stop()
	
end


  
function love.keypressed(key, scan_code, is_repeat)
  
	if game_state == 'menu' then
	  menu_keypressed(key)
  
	elseif game_state == 'how-to-play' then
	  how_to_play_keypressed(key)
  
	else -- game_state == 'game'
	  game_keypressed(key)
  
	end
  
end

function menu_keypressed(key)
  
	-- pressing Esc on the main menu quits the game
	if key == 'escape' then
	  love.event.quit()
  
	-- pressing up selects the previous menu item, wrapping to the bottom if necessary
	elseif key == 'up' then
  
	  selected_menu_item = selected_menu_item - 1
  
	  if selected_menu_item < 1 then
		selected_menu_item = #menus
	  end
  
	-- pressing down selects the next menu item, wrapping to the top if necessary
	elseif key == 'down' then
  
	  selected_menu_item = selected_menu_item + 1
  
	  if selected_menu_item > #menus then
		selected_menu_item = 1
	  end
  
	-- pressing enter changes the game state (or quits the game)
	elseif key == 'return' or key == 'kpenter' then
  
		if menus[selected_menu_item] == 'Play' then
			game_state = 'game'
			
			
		elseif menus[selected_menu_item] == 'How To Play' then
			game_state = 'how-to-play'
			love.graphics.printf("Control Keys for Player 1:\nUP, DOWN, LEFT, RIGHT ARROW KEYS\nUse SPACE BAR to drop a bomb\n\n", 0, 250, window_width, 'center')
			love.graphics.printf("Control Keys for Player 2:\nW, S, A, D KEYS\n\nUse X to drop a bomb", 0, 550, window_width, 'center')

		elseif menus[selected_menu_item] == 'New Game' then
			seconds = 180
			love.load()
			game_state = 'game'

		elseif menus[selected_menu_item] == 'Quit' then
			love.event.quit()

		end

	end
  
end
  
function how_to_play_keypressed(key)
	if key == 'escape' then
	  game_state = 'menu'
	end
  
  end
  
  function game_keypressed(key)
	if key == 'escape' then
	  game_state = 'menu'
	  
	elseif key == 'tab' then
		debug = not debug

	elseif key == 'space' then
		if player.usedBombs < player.maxBombs then
			local tile = map:toWorld(map:toTile(player.position + Vector(6, 4)))
			local occupied = false
			local items, _ = world:queryRect(tile.x, tile.y, 15, 15)
			for _, item in ipairs(items) do
				if item:is(Bomb) then
					occupied = true
				end
			end

			if not occupied then
				local bomb = Bomb(player, tile.x, tile.y)
				table.insert(objects, bomb)
				player.usedBombs = player.usedBombs + 1
			end
		end
	end
  
end


  