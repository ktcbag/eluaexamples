-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--		eLua Race Game
--
--
--													LED Lab @ PUC-Rio
--																2010
--
--  v0.0.1
--    This is the first version of the new eLua game!
--      - It does have checkpoints
--      - The speed and controls are being adjusted
--
--  To Do:
--    - Multiple levels
--    - Code cleanup
--    - Button pooling while waiting
--    - Comments, comments and more comments
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
MAX_X = 18
MAX_Y = 12
COL_SIZE = math.ceil( MAX_Y / 4 )
CAR_CHAR = ">"
WALL_CHAR = "*"

local pressed = {}

level2="801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801861861861861861861861801801C03A05909891891891891891891891891891891891891891891891891891891891891891891891891891891891909E078018F1861891801861801801801F9F801801801E7F801801F9F801801801CFF801801801801FC78018018018018018019FF801801801801E0F801801801801FF980180180180180180180380780F81F83F87F8FF9FFBFFBFFBFFBFFBFF9FFDFFCFFCFFCFFCFFCFFCFFC7FC3FE3FE3FE3FE3FE1FE1FE1FE1FE1FE1FE1FE1FE1FE1FE1FE1FE1F8C18C18C18C18C18C18C1801801FFF801801801801801801AABA21A21A21A21A319099059059059059259219218218238218218618C1981909809809C09A09A49A45A65A65A45A49A49A53A53A09A01901881841821841881901A01C01801801801925925925925925925925925925925925925925925925925925A49A91AA1AA1AA1AA1AA7A81A81A41A21921CA1AA7AA1CA18B9921A21921D9195DA11911D21D21927921921B21921921921D21921929929B2992D92992992992B92992992992992D949949851851851851851891921A21A21A21A21A21A61AC3A07A0D919891811811889845C45845849A25A15A15A25A49A51A51A51A91A91AA7AA7A91A91A51A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49A49801801801FFF801801801801801801801801F9F801801801801801801801801801801841861BF1BF9BFDBF9BF18618418018098098098098098098098198118318218638438C788F89F99F93F93F99FC9FE8FE8FEC7E47F47F47F4FF4FF47F67E73EF3CF3CE3DE79C79C79C7B87987C87EC3E43E43EC3EC1CC1DC1DC1DC19C19C1BC1BC1BC1BC19C19C1DC1DC1DC19F79F7BF7BC19C19C19C19C19C19C1BDFBDF801801801801801801801801801801801801801801801BFDA05A05A05A05A05A05A05A05905885A45B25A95A4DA25A11A09A05A05A05A05BFD801801801801801801801801801801801801801801801801801801801B0DB0DB0DB0DB0DB0DB0DB0DB0DBFDBFDBFDBFDBFDBFDBFDBFDBFDB0DB0DB0DB0DB0DB0DB0DB0D801801C03C03C03E07801801861861891909861861861C63A65969861861801801801891891891891891891F9F801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801801"

local level = level2
local level_size = string.len( level ) / 3
local level_buffer = {}

--require( pd.platform() )

function init()
BTN_UP      = pio.PE_0
BTN_DOWN    = pio.PE_1
BTN_LEFT    = pio.PE_2
BTN_RIGHT   = pio.PE_3
BTN_SELECT  = pio.PF_1

btn_pressed = function( button )
  return pio.pin.getval( button ) == 0
end

LED_1 = pio.PF_0

disp = lm3s.disp

pio.pin.setdir( pio.INPUT, BTN_UP, BTN_DOWN, BTN_LEFT, BTN_RIGHT, BTN_SELECT )
pio.pin.setpull( pio.PULLUP, BTN_UP, BTN_DOWN, BTN_LEFT, BTN_RIGHT, BTN_SELECT )

pio.pin.setdir( pio.OUTPUT, LED_1 )
end

function initLevelBuffer( col )
  for i = 0, MAX_X + 1 do
    local col = string.sub( level, COL_SIZE*( col + i ) + 1, COL_SIZE * ( col + i + 1 ) )
    loadstring( "c = 0x"..col )()
    level_buffer[ i ] = c
  end
end

function updateAll()
  collumn = collumn + 1
  updateCarPos()
  updateScreen()
end

function updateScreen()
  local col = string.sub( level, COL_SIZE * ( collumn + MAX_X ) + 1 , COL_SIZE * ( collumn + MAX_X + 1 ) )
  loadstring( "c = 0x"..col )()
  updateLevelBuffer( c )
  for i = MAX_X - 1, 0, -1 do
  --local col = string.sub( level, COL_SIZE*collumn + COL_SIZE * i, COL_SIZE * collumn + COL_SIZE * i + COL_SIZE )
  --loadstring( "c = 0x"..col )()
    for j = 0, MAX_Y - 1 do
      if j ~= cy or i ~= 0 then
        if bit.isset( level_buffer[ i ], j ) then
          disp.print( WALL_CHAR, i*6, j*8, 8 )
        else
          disp.print( " ", i*6, j*8, 0 )
        end
      end
    end
  end
end

function updateLevelBuffer( col, ... )
  if not col then
    return
  end
  for i = 0, MAX_X - 2 do
    level_buffer[ i ] = level_buffer[ i + 1]
 -- table.remove( level_buffer, 1 )
 -- table.insert( level_buffer, col )
  end
  level_buffer[ MAX_X - 1 ] = col
  updateLevelBuffer( ... )
end

-- Car functions
function drawCar( y, color, movement )
  if ( movement == 0 ) then
    disp.print( CAR_CHAR, 0, y * 8, color)
  elseif ( movement > 0 ) then			-- Car moving Down
    disp.print( CAR_CHAR, 0, ( y - 1 ) * 8, 0 )
    disp.print( CAR_CHAR, 0, y * 8, color )
  elseif ( movement < 0 ) then		-- Car moving Up
    disp.print( CAR_CHAR, 0, ( y + 1 ) * 8, 0 )
    disp.print( CAR_CHAR, 0, y * 8, color )
  end
end

function updateCarPos()
  local mov = 0
  if btn_pressed( BTN_UP ) then
    if ( cy > 0 ) then
      mov = -1
    end
  elseif btn_pressed( BTN_DOWN ) then
    if cy < MAX_Y - 1 then
      mov = 1
    end
  end
  cy = cy + mov
  drawCar( cy, 11, mov )
end




function drawWall( x, y )
  for i = 0, y, 7 do
    disp.print( "|", xcanvas + 1, i, 0 )
  end
  xcanvas = x
  for i = 0, y, 7 do
    disp.print( "|", xcanvas + 1, i, 6 )
  end

end

function buttonClicked( button )
  if btn_pressed( button ) then
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
init()

disp.init( 1000000 )

collectgarbage("collect")

local checkpoint = 0

local tmrid = 2
local time = 0
repeat
  ycanvas = 96
  cy = MAX_Y / 2												-- Car's Y position ( X position not needed, always 0 )
  delayTime = 100000												-- This value is used for the main delay, to make the game speed faster or slower
  collumn = checkpoint - 1
  win = false
  LEVEL_X = level_size - ( MAX_X + 1 )

  initLevelBuffer( checkpoint )

  timeStart = tmr.start( tmrid )

  disp.clear()

  for i = 0, ycanvas, 7 do
    disp.print( "|", 106, i, 6 )
  end

  timeStart = tmr.start( tmrid )

  while ( true ) do
    updateAll()
  --local col = string.sub( level, COL_SIZE*collumn, COL_SIZE*collumn + COL_SIZE )
  --loadstring( "c = 0x"..col )()
    if level_buffer[ 0 ] == 0xFFF then
      checkpoint = collumn
    elseif bit.isset( level_buffer[ 0 ], cy ) then
      break
    end

    if collumn == LEVEL_X then
      disp.print( "Congratulations!", 10, 48, 15 )
      tmr.delay( 0, 3000000 )
      disp.print( "Congratulations!", 10, 48, 0 )
      win = true
      break
    end
    tmr.delay( 0, delayTime )


    if buttonClicked( BTN_RIGHT ) and delayTime > 0 then
      delayTime = delayTime - 20000
      print(delayTime)
    end
    if buttonClicked( BTN_LEFT ) and delayTime < 100000 then
      delayTime = delayTime + 20000
      print(delayTime)
    end

    local dt = tmr.gettimediff( tmrid, timeStart, tmr.read( tmrid ) )
    if dt >= 1000000 then
      time = math.floor( time + ( dt / 1000000 ) )
      timeStart = tmr.read( tmrid )
    end
    disp.print( time, 110, 0, 6 )

    collectgarbage("collect")
  end
-------------------------------------------
-- End of Game
-------------------------------------------

  disp.clear()
  if not win then
    disp.print( "Game Over :(", 30, 20, 11 )
    disp.print( "Your current time is "..tostring(time), 5, 40, 11 )
    disp.print( "SELECT to restart", 6, 70, 11 )
  else
    disp.print( "You won!!!", 30, 20, 11 )
    disp.print( "Your time was "..tostring(time), 15, 40, 11 )
    disp.print( "SELECT to restart", 6, 70, 11 )
  end
  enough = true
  for i=1, 100000 do
    if btn_pressed( BTN_SELECT ) then
    print( "Checkpoint = ", checkpoint )
      enough = false
      break
    end
  end

until ( enough )

disp.off()
