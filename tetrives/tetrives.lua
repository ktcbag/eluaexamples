-------------------------------------------------------------------------------
--
--		eLua Tetris Game
--
-- LED Lab @ PUC-Rio - 2009
--   Dado Sutter
--   Ives Negreiros
--   Ricardo Rosa
--   Pedro Bittencourt
--   Teo Benjamin
-- 

-- Initial Version by Ives Negreiros, August 2009
--    Needs revisions and code cleaning
--		
-------------------------------------------------------------------------------
local Vmax = 22							-- number of pieces in vertical +1
local Hmax = 12							-- number of pieces horizontally + 2
local score = 0							-- Player's score
local highscore = 0						-- Player's highscore
local nextpiece = 0						--This is the code for the next piece
local PieceV = 0				   		--This is the vertical position of the peice
local PieceH = 0				   		--This is the horizontal position of the peice
local level = 1							--This variable is the level
local RotateType = 0			   		--This is the type of rotation of piece
local totalLines = 0			   		--This variable is the total number of lines made by the player
local seed = 0

local gamemap = {}						--This is the table for the game map
for i = 1, Vmax, 1 do
	gamemap[ i ] = {}
end

-- Initial information
require( pd.platform() )
disp.init( 1000000 )

disp.print( "Tetrives", 30, 30, 11 )
disp.print( "Press SELECT", 30, 60, 11 )
while LM3S.btnpressed( LM3S.BTN_SELECT ) == false do
	seed = seed + 1
end
math.randomseed( seed )
disp.clear()

function scanpiece()
   if(nextpiece == 1) then
      nextpiecemap = {{1,1},{1,1}}
      nextRotateType = 0

   elseif(nextpiece == 2) then
      nextpiecemap = {{1,1,0},{0,1,1},{0,0,0}}
      nextRotateType = 1

   elseif(nextpiece == 3) then
      nextpiecemap = {{0,1,1},{1,1,0},{0,0,0}}
      nextRotateType = 1

   elseif(nextpiece == 4) then
      nextpiecemap = {{0,0,1},{1,1,1},{0,0,0}}
      nextRotateType = 3

   elseif(nextpiece == 5) then
      nextpiecemap = {{1,0,0},{1,1,1},{0,0,0}}
      nextRotateType = 3

   elseif(nextpiece == 6) then
      nextpiecemap = {{0,1,0},{1,1,1},{0,0,0}}
      nextRotateType = 3

   elseif(nextpiece == 7) then
      nextpiecemap = {{0,0,0,0},{1,1,1,1},{0,0,0,0},{0,0,0,0}}
      nextRotateType = 4
   end
end

function drawWalls()
   for i = 6, 63, 3 do
      disp.print( "|", 3, i, 11 )
   end
   for i = 6, 63, 3 do
      disp.print( "|", 118, i, 11 )
   end
   for i = 3, 118, 4 do
      disp.print( "-", i, 65, 11 )
   end
   for i = 3, 118, 4 do
      disp.print( "-", i, 2, 11 )
   end
end

function sound()
	pwm.start( 1 )
	tmr.delay( 0, 20000 )
	pwm.stop( 1 )
end

function printData()
   disp.print( "Score:"..tostring(score), 0, 88, 8 )
   disp.print( "Level:"..tostring(level), 0, 80, 8 )
end

function drawpiece()
	for i in ipairs( piecemap ) do
		for j in ipairs( piecemap[ i ] ) do
			if( piecemap[ i ][ j ] == 1) then
				disp.print("*", (PieceV+i-1)*6, (PieceH+j-1)*6, 11)
			end
		end
	end
end

function erasepiece()
	for i in ipairs( piecemap ) do
		for j in ipairs( piecemap[ i ] ) do
         if( piecemap[ i ][ j ] == 1) then
				disp.print("*", (PieceV+i-1)*6, (PieceH+j-1)*6, 0)
			end
		end
	end
end

function moveDown()
   free = 0
	for i in ipairs(piecemap) do
		for j in ipairs(piecemap[ i ] ) do
			if( piecemap[ i ][ j ] == 1) then
				if(gamemap[PieceV+i-1][PieceH+j] == 0) then
				  free = free + 1
				end
			end
		end
	end
	if (free==4) then
		erasepiece()
		PieceV = PieceV - 1
		drawpiece()
	else
		for i in ipairs(piecemap) do
			for j in ipairs(piecemap[ i ] ) do
            if( piecemap[ i ][ j ] == 1) then
               gamemap[PieceV+i][PieceH+j] = 1
            end
			end
		end
		testLine()
		createNewPiece()
	end
end

function moveLeft()
   free = 0
	for i in ipairs(piecemap) do
		for j in ipairs(piecemap[ i ] ) do
			if( piecemap[ i ][ j ] == 1) then
				if(gamemap[PieceV+i][PieceH+j-1] == 0) then
				  free = free + 1
				end
			end
		end
	end
	if (free==4) then
		erasepiece()
		PieceH = PieceH - 1
		drawpiece()
	end
end

function moveRight()
   free = 0
	for i in ipairs(piecemap) do
		for j in ipairs(piecemap[ i ] ) do
			if( piecemap[ i ][ j ] == 1) then
				if(gamemap[PieceV+i][PieceH+j+1] == 0) then
				  free = free + 1
				end
			end
		end
	end
	if (free==4) then
		erasepiece()
		PieceH = PieceH + 1
		drawpiece()
	end
end

function rotate()
	piecerot = {}
	for i = 1, 4, 1 do
		piecerot[ i ] = {}
	end
   free = 0
   erasepiece()
	if (RotateType == 1) then
		for i in ipairs(piecemap) do
			for j in ipairs(piecemap[ i ] ) do
				if( piecemap[ i ][ j ] == 1) then
					if(gamemap[PieceV+j][4-i+PieceH] == 0) then
						free = free + 1
					end
				end
			end
		end
		if(free ==4) then
			RotateType = 2
			for i in ipairs(piecemap) do
				for j in ipairs(piecemap[ i ] ) do
					piecerot[i][j] = piecemap[j][4-i]
				end
			end
			piecemap = piecerot
		end

	elseif (RotateType == 2) then
		for i in ipairs(piecemap) do
			for j in ipairs(piecemap[ i ] ) do
				if( piecemap[ i ][ j ] == 1) then
					if(gamemap[4-j+PieceV][PieceH+i] == 0) then
						free = free + 1
					end
				end
			end
		end
		if(free ==4) then
			RotateType = 1
			for i in ipairs(piecemap) do
				for j in ipairs(piecemap[ i ] ) do
					piecerot[i][j] = piecemap[4-j][i]
				end
			end
			piecemap = piecerot
		end

	elseif (RotateType == 3) then
		for i in ipairs(piecemap) do
			for j in ipairs(piecemap[ i ] ) do
				if( piecemap[ i ][ j ] == 1) then
					if(gamemap[PieceV+j][4-i+PieceH] == 0) then
						free = free + 1
					end
				end
			end
		end
		if(free ==4) then
			for i in ipairs(piecemap) do
				for j in ipairs(piecemap[ i ] ) do
					piecerot[i][j] = piecemap[j][4-i]
				end
			end
			piecemap = piecerot
		end

	elseif (RotateType == 4) then
		for i in ipairs(piecemap) do
			for j in ipairs(piecemap[ i ] ) do
				if( piecemap[ i ][ j ] == 1) then
					if(gamemap[PieceV+j][PieceH+i] == 0) then
						free = free + 1
					end
				end
			end
		end
		if(free ==4) then
			for i in ipairs(piecemap) do
				for j in ipairs(piecemap[ i ] ) do
					piecerot[i][j] = piecemap[j][i]
				end
			end
			piecemap = piecerot
		end
	end
	drawpiece()
	sound()
end

function removeLine( line )
	for i =line, Vmax-2, 1 do
		for j=2, Hmax-1, 1 do
			disp.print("*", (i-1)*6, (j-1)*6, 0)
			gamemap[i][j] = gamemap[i+1][j]
			if(gamemap[i][j]==1) then
				disp.print("*", (i-1)*6, (j-1)*6, 11)
			end
		end
	end
end

function testLine()
	lines = 0
	i = 2
	while (i<Vmax) do
      j = 2
		while (j<Hmax) do
			if( gamemap[i][j] == 0) then
				break
			elseif(j==Hmax-1) then
				removeLine(i)
				lines = lines + 1
				i = i - 1
            break
			end
			j = j + 1
		end
      i = i + 1
	end
	totalLines = totalLines + lines
	score = score + 100*level*lines*lines
	if( totalLines >= 8 and level < 4) then
		level = level + 1
		totalLines = 0
	end
end

function createNewPiece()
	nextpiece = math.random(7)
	piecemap = nextpiecemap
   RotateType = nextRotateType
	PieceV = 18
	PieceH = 4
   scanpiece ()
	for i=1, 2, 1 do
		for j=1, 4, 1 do
			disp.print("*", 94+(j*6), 78+(i*6), 0)
		end
	end
   for i in ipairs( nextpiecemap ) do
		if(i == 3) then break end
		for j in ipairs( nextpiecemap[ i ] ) do
			if( nextpiecemap[ i ][ j ] == 1) then
				disp.print("*", 94+(j*6), 78+((3-i)*6), 11)
			end
		end
	end
	drawpiece()
end

---------------------------------------------------------------------------------
--																			   --
--				                 MAIN LOOP							           --
--																			   --
---------------------------------------------------------------------------------
repeat

   for i in ipairs(gamemap) do
      for j = 1, Hmax, 1 do
         if( j == 1 or j == Hmax or i==1 or i==21) then
            gamemap[i][j] = 1
         else
            gamemap[i][j] = 0
         end
      end
   end
   level = 1
   score = 0
   pwm.setclock( 1, 25000000 )
   pwm.setup( 1, 1000, 70 )
   drawWalls()
   nextpiece = math.random(7)
   scanpiece ()
   createNewPiece()
   collectgarbage("collect")
   while true do
      printData ()
	  Tmax = 11 - 2*level
      for i=1, Tmax, 1 do
         if LM3S.btnpressed( LM3S.BTN_UP ) then moveLeft() end
         if LM3S.btnpressed( LM3S.BTN_DOWN ) then moveRight() end
         if LM3S.btnpressed( LM3S.BTN_RIGHT ) then rotate() end
         if LM3S.btnpressed( LM3S.BTN_LEFT ) then
            score = score +1
            tmr.delay(1, 30000)
            break
         end
         tmr.delay(1, 70000)
      end
      moveDown()
      if(gamemap[PieceV+2][PieceH+2] == 1) then
         break
      end
   collectgarbage("collect")
   end

   if score > highscore then
      highscore = score
   end
   disp.clear()
   disp.print( "Game Over :(", 30, 20, 11 )
   disp.print( "Your score was "..tostring(score), 0, 40, 11 )
   disp.print( "Highscore: "..tostring(highscore), 15, 50, 11 )
   disp.print( "SELECT to restart", 6, 70, 11 )
   enough = true
   for i=1, 1000000 do
      if LM3S.btnpressed( LM3S.BTN_SELECT ) then
         enough = false
         break
      end
   end
   disp.clear()  
until ( enough )
disp.off()
