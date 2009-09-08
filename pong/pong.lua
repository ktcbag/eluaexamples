-------------------------------------------------------------------------------
--
--		eLua Pong Game
--
-- LED Lab @ PUC-Rio - 2009
--   Dado Sutter
--   Ives Negreiros
--   Ricardo Rosa
--   Pedro Bittencourt
--   Teo Benjamin
-- 

-- Initial Version by Dado Sutter, Fev 2009
--    This had only the ball bouncing on walls, paddle and paddle movement
--	
-- Greatly enhanced by Teo Benjamin, adding:
--    Score, resizeable paddles, levels/speeds, 
--
--		
-------------------------------------------------------------------------------

require( pd.platform() )

local items = {}
local pressed = {}

local itemFunction = {
["L"] = function ()
          drawPaddle( py, 0, 0 )
          if pSize < pSizeMax then
            pSize = pSize + 1
          end
          drawPaddle( py, 11, 0 )
        end,
["S"] = function ()
  	drawPaddle( py, 0, 0 )
  	if pSize > pSizeMin then
  		pSize = pSize - 1
	end
	drawPaddle( py, 11, 0 )
	end,

["?"] = function ()
		item = items[ math.random( #items ) ]
  	useItem()
  end,

["*"] = function ()
	end,

["P"] = function ()
  	score = score + dscore
  end,

["D"] = function ()
  	score = score * 2
  end,

["Z"] = function ()
  	lm3s.disp.print( tostring( score ), 111, 89, 0 )
  	score = 0
  end,

["T"] = function ()
		lm3s.disp.print( ball, bx, by, 0 )
		by = math.random( 82 )
		lm3s.disp.print( ball, bx, by, 15 )
	end,
["F"] = function()
		if delayTime >= 1000 then
			delayTime = delayTime - 1000
		end
	end,
}


-- Menu Funcions
-- If you have enough memory, use this part. If not, forget it.
--[[
function menu()
	tmr.delay( 0, 150000 )
	lm3s.disp.clear()
  local cursorPos = 1
	local cursorChange = 0
	lm3s.disp.print("Play", 30, 35, 10 )
	lm3s.disp.print("Instructions", 30, 50, 10 )
	lm3s.disp.print("Credits", 30, 65, 10 )
	for i = 1, 3, 1 do
			if i == cursorPos then
				lm3s.disp.print("*", 22, 20 + ( 15*i ), 10 )
			else
				lm3s.disp.print("*", 22, 20 + ( 15*i ), 0 )
			end
	end

	while ( ( LM3S.btnpressed( LM3S.BTN_SELECT ) ) == false ) do
		if cursorChange == 0 then
			tmr.delay( 0, 75000 )
			if LM3S.btnpressed( LM3S.BTN_UP ) then
  	  	cursorChange = -1
  		elseif LM3S.btnpressed( LM3S.BTN_DOWN ) then
      	cursorChange = 1
      end
    else
  		if ( ( LM3S.btnpressed( LM3S.BTN_RIGHT ) ) == false and ( LM3S.btnpressed( LM3S.BTN_LEFT ) ) == false ) then
    		cursorPos = cursorPos + cursorChange
      	if cursorPos > 3 then
      		cursorPos = 3
      	elseif cursorPos < 1 then
      		cursorPos = 1
      	end
      	cursorChange = 0
      	tmr.delay( 0, 75000 )
    	end
    end
    for i = 1, 3, 1 do
			if i == cursorPos then
				lm3s.disp.print("*", 22, 20 + ( 15*i ), 10 )
			else
				lm3s.disp.print("*", 22, 20 + ( 15*i ), 0 )
			end
		end
		collectgarbage("collect")
  end
	if cursorPos == 1 then
		return
	elseif cursorPos == 2 then
		Instructions()
	elseif cursorPos == 3 then
		Credits()
	end

end

function Instructions()
	local InstrPage = 1
	local pageChange = 0
	lm3s.disp.clear()
	tmr.delay( 0, 150000 )
	while ( ( LM3S.btnpressed( LM3S.BTN_SELECT ) ) == false ) do
		if InstrPage == 1 then
			lm3s.disp.print("L- Large", 5, 10, 10 )
			lm3s.disp.print("S- Small", 5, 20, 10 )
			lm3s.disp.print("Z- Points = Zero", 5, 30, 10 )
			lm3s.disp.print("?- Random", 5, 40, 10 )
			lm3s.disp.print("*- Nothing!", 5, 50, 10 )
			collectgarbage("collect")
		elseif InstrPage == 2 then
			lm3s.disp.print("F- Faster", 8, 10, 10 )
			lm3s.disp.print("T- Teleport", 8, 20, 10 )
			lm3s.disp.print("D- Double Points", 8, 30, 10 )
			lm3s.disp.print("P- More Points", 8, 40, 10 )
		end
		if pageChange == 0 then
			tmr.delay( 0, 75000 )
			if LM3S.btnpressed( LM3S.BTN_UP ) then
  	  	pageChange = -1
  		elseif LM3S.btnpressed( LM3S.BTN_DOWN ) then
      	pageChange = 1
      end
    else
  		if not ( ( LM3S.btnpressed( LM3S.BTN_RIGHT ) ) or ( LM3S.btnpressed( LM3S.BTN_LEFT ) ) ) then
    		InstrPage = InstrPage + pageChange
      	if InstrPage > 2 then
      		InstrPage = 2
      	elseif InstrPage < 1 then
      		InstrPage = 1
      	end
      	pageChange = 0
      	tmr.delay( 0, 75000 )
  			lm3s.disp.clear()
    	end
    end
		collectgarbage("collect")
	end
	menu()
end

function Credits()
	tmr.delay( 0, 150000 )
	lm3s.disp.clear()
		lm3s.disp.print("eLua Pong is a game", 8, 10, 10 )
		lm3s.disp.print("designed by LED Lab", 8, 20, 10 )
		lm3s.disp.print("Teo,", 5, 30, 10 )
		lm3s.disp.print("Dado,", 5, 40, 10 )
		lm3s.disp.print("Ives,", 5, 50, 10 )
		lm3s.disp.print("Ricardo", 5, 60, 10 )
		lm3s.disp.print("Have fun with eLua :)", 0, 80, 10 )
		collectgarbage("collect")
	while ( ( LM3S.btnpressed( LM3S.BTN_SELECT ) ) == false ) do
	end
	menu()
end

--]]


-- Paddle functions
function drawPaddle( y, color, movement )
  if ( movement == 0 ) then
    for i = 0, pSize, 1 do
      lm3s.disp.print("|", 0, y + ( i * 6 ),  color)
    end
  elseif ( movement > 0 ) then			-- Paddle moving Down
    if y < 8 then
      lm3s.disp.print("|", 0, 0,  0)
    else
      lm3s.disp.print("|", 0, y - 8 , 0)
    end
    for i = 0, pSize, 1 do
      lm3s.disp.print("|", 0, y + ( i * 6 ),  color)
    end
  elseif ( movement < 0 ) then		-- Paddle moving Up
    lm3s.disp.print("|", 0, y + ( ( pSize + 1 ) * 6 ) + 2 , 0)
    for i = 0, pSize, 1 do
      lm3s.disp.print("|", 0, y + ( i * 6 ),  color)
    end
  end
end

function updatePaddlePos()
  if LM3S.btnpressed( LM3S.BTN_UP ) then
    if ( py > 0 ) then
      py = py - 1
      drawPaddle( py, 11, -1 )
    else
    	tmr.delay( 1, 1700 )
    end
  elseif LM3S.btnpressed( LM3S.BTN_DOWN ) then
    if ( py + ( pSize*6 ) + 1 < 90 ) then
      py = py + 1
      drawPaddle( py, 11, 1 )
    else
    	tmr.delay( 1, 1600 )
    end
  else
  	drawPaddle( py, 11, 0 )
    tmr.delay( 1, 300 ) -- Maintain function processing time aprox the same
  end
end

-- Ball functions
function updateBallPos()
  if( ( bx + 5 >= xcanvas ) or ( bx <= 4 ) ) then
    dx = -dx;
    if dx == -1 and item == false then
     	createItem()
    end
  end

  if(( by >= 90 - dy ) or ( by <= 1 - dy )) then
    dy = -dy;
  end
  lm3s.disp.print( ball, bx, by, 0 )
  bx, by = ( bx + dx ), ( by + dy );
  lm3s.disp.print( ball, bx, by, 15 )
end



function drawWall( x, y )
	for i = 0, y, 7 do
  	lm3s.disp.print( "|", xcanvas + 1, i, 0 )
  end
  xcanvas = x
  for i = 0, y, 7 do
  	lm3s.disp.print( "|", xcanvas + 1, i, 6 )
  end

end

-- Item Functions
function createItem()
	item = items[ math.random( #items ) ]
	ix = xcanvas - 10
	iy = by
end

function uploaditems()
	for k,v in pairs( itemFunction ) do
		table.insert( items, k )
	end
end

function updateItemPos()
  if item then
		if ( ix <= 4 ) then
    	if ( ( iy + 8 < py ) or ( iy > py + ( pSize*6 ) + 8 ) ) == false then
    		useItem()
			end
  		lm3s.disp.print( item, ix, iy, 0 )
  		item = false
  		return
  	end
  	lm3s.disp.print( item, ix, iy, 0 )
  	ix = ix - 2
  	lm3s.disp.print( item, ix, iy, 10 )
	end
end

function useItem()
	itemFunction[ item ]()
end


function buttonClicked( button )
	if LM3S.btnpressed( button ) then
		pressed[ button ] = true
	else
		if pressed[ button ] then
			pressed[ button ] = false
			return true
		end
		pressed[ button ] = false
	end
	return false
end


------------ MAIN ------------
--lm3s_init()

uploaditems()
lm3s.disp.init( 1000000 )
tmr.start( 1 )
--menu()

math.randomseed( tmr.read( 1 ) )

collectgarbage("collect")

local highscore = 0

repeat

  xcanvas = 124
  ycanvas = 97
  bx = 5														-- Ball's X position
  by = math.random( ( ycanvas - 8 ) / 2 ) + ( ycanvas / 4 )		-- Ball's Y position -> starts in a random position
  dx = 1														-- Ball's X movement ( 1 = moving right; -1 = moving left )
  dy = 1														-- Ball's Y movement ( 1 = moving down; -1 = moving up )
  py = by - 4													-- Paddle's Y position ( X position not needed, always 0 )
  ix = 0														-- Item's X position
  iy = 0														-- Item's Y position ( fix for each item )
  score = 0														-- Player's score
  dscore = 1													-- dscore represents the level in this case
  ball = "*"													-- The char that is printed for the ball
  item = false													-- This is the char that represents the item ( if false, there is no item )
  pSize = 2														-- Paddle size = ( 6 * ( pSize + 1 ) ) + 2
  pSizeMax = 4													-- Max pSize value
  pSizeMin = 0													-- Min pSize value
  delayTime = 10000												-- This value is used for the main delay, to make the game speed faster or slower
  paddleHits = 0												-- Counts the number of hits the paddle makes




  lm3s.disp.clear()
  drawPaddle( py, 11, 0 )

  for i = 0, ycanvas, 7 do
  	lm3s.disp.print( "|", xcanvas + 1, i, 6 )
  end

  while ( true ) do

    for i = 0, 1 do
      updatePaddlePos()
    end
		tmr.delay ( 0, delayTime )
    updateBallPos()
    updateItemPos()
    if ( bx <= 4 ) then
      if (( by + 8 < py ) or ( by > py + ( pSize*6 ) + 8 ) ) then
        break
      else
      	score = score + dscore
      	paddleHits = paddleHits + 1
      end
    end

	if buttonClicked( LM3S.BTN_RIGHT ) then
		delayTime = delayTime - 2000
      	dscore = dscore + 1
	end
	if buttonClicked( LM3S.BTN_LEFT ) then
		delayTime = delayTime + 2000
      	dscore = dscore - 1
	end

    if ( paddleHits == 5 ) and xcanvas > 80 then
    	paddleHits = 0
		drawWall( xcanvas - 5, ycanvas )
  	end


    lm3s.disp.print( tostring( dscore ), 118, 0, 6 )
    lm3s.disp.print( tostring( score ), 111, 89, 6 )
    collectgarbage("collect")
  end
-------------------------------------------
-- End of Game
-------------------------------------------
  if score > highscore then
    highscore = score
  end

  lm3s.disp.clear()
  lm3s.disp.print( "Game Over :(", 30, 20, 11 )
  lm3s.disp.print( "Your score was "..tostring(score), 15, 40, 11 )
  lm3s.disp.print( "Highscore: "..tostring(highscore), 15, 50, 11 )
  lm3s.disp.print( "SELECT to restart", 6, 70, 11 )
  enough = true
  for i=1, 100000 do
    if LM3S.btnpressed( LM3S.BTN_SELECT ) then
      enough = false
      break
    end
  end

until ( enough )
disp.off()
