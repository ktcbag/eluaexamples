--------------------------------------------------------------------------------
--
-- VFD - Vacuum Fluorescent Display tube control for eLua (www.eluaproject.net)
--
-- Implemented for IV-18 tubes and MAX6921 decoders
-- Pls see www.eluaproject.net for more details
--
-- Feb 2010
--
-- Dado Sutter, Fernando Araújo, Marcelo Politzer, Téo Benjamin
-- IV-18 Tubes were a gift from Bogdan Marinescu
--
--------------------------------------------------------------------------------

local pio, bit, tmr, pd, mbed       = pio, bit, tmr, pd, mbed
local pairs, ipairs, collectgarbage = pairs, ipairs, collectgarbage
local strbyte, strsub               = string.byte, string.sub
local mathmodf, mathfmod, mathlog10 = math.modf, math.fmod, math.log10

module (...)

-- Module and interface initialization
-- Can be called with an optional table parameter, with optional fields to
-- setup non-default values or configure unknown platform targets.
function init( t )
  t = t or {}
  WORD_SIZE = t.word_size or 17     -- Can be extended for multiple VFD control
  if pd.board() == "ELUA-PUC" then
    clk_pin   = t.clk_pin or pio.P0_24
    din_pin   = t.din_pin or pio.P0_26
    LOAD_PIN  = t.load_pin or pio.P0_28
--  BLANK_PIN = t.blank_pin or pwm pin on blank ctrl to set intensity ....
  elseif pd.board() == "EK-LM3S8962" then
    clk_pin   = t.clk_pin or pio.PC_5
    din_pin   = t.din_pin or pio.PG_0
    load_pin  = t.load_pin or pio.PC_7
  elseif pd.board() == "STR-E912" then
    clk_pin   = t.clk_pin or pio.P6_0
    din_pin   = t.din_pin or pio.P6_1
    load_pin  = t.load_pin or pio.P6_2
  elseif pd.board() == "MBED" then
    clk_pin   = t.clk_pin or mbed.pio.P5
    din_pin   = t.din_pin or mbed.pio.P6
    load_pin  = t.load_pin or mbed.pio.P7

--[[
  elseif pd.board() == "EK-LM3S6965" then
    clk_pin   = t.clk_pin or 
    din_pin   = t.din_pin or 
    load_pin  = t.load_pin or 
  elseif pd.board() == "ELUA-PUC" then
    clk_pin   = t.clk_pin or 
    din_pin   = t.din_pin or 
    load_pin  = t.load_pin or 
  elseif pd.board == "ATEVK1100" then
    clk_pin   = t.clk_pin or 
    din_pin   = t.din_pin or 
    load_pin  = t.load_pin or 
--]]    
  elseif ( clk_pin and din_pin and load_pin ) == nil then
    error("vfd.init() does not know your platform and/or you haven't correctly specified clk_pin, din_pin or load_pin" )
  end
  pio.pin.setdir( pio.OUTPUT, clk_pin, load_pin, din_pin )

-- VFD chars table
-- Each value is the segment byte to write the key on vfd
-- Table is indexed by the chars
  vfdc = { [ "0" ] = 0xFC, 
           [ "1" ] = 0x60, 
           [ "2" ] = 0xDA, 
           [ "3" ] = 0xF2, 
           [ "4" ] = 0x66, 
           [ "5" ] = 0xB6, 
           [ "6" ] = 0xBE, 
           [ "7" ] = 0xE0, 
           [ "8" ] = 0xFE, 
           [ "9" ] = 0xE6,
           [ " " ] = 0x00,
           [ "_" ] = 0x10,
           [ "-" ] = 0x02,
           [ "=" ] = 0x12,
           [ "E" ] = 0x9E,
           [ "L" ] = 0x1C,
           [ "U" ] = 0x7C,
           [ "A" ] = 0xEE,
           [ "S" ] = 0xB6,
           [ "O" ] = 0xFC,
           [ "L" ] = 0x1C,
           [ "P" ] = 0xCE,
           [ "C" ] = 0x9C,
           [ "I" ] = 0x60,
           [ "F" ] = 0x8E
--           [ "." ] = 0x01,   -- lit on the same digit of a char
         }

-- Another VFD char table, now indexed by string.byte( char ), to avoid
-- creating too many orphan strings when indexing by string.sub 
-- and forcing the garbage collector too soon
-- Only one of these tables (vfdc or vfdb) will be needed on final version
-- (probably vfdb)
  vfdb = {}       
  for k, v in pairs( vfdc ) do
    vfdb[ strbyte( k ) ] = v
  end
 vfdc = nil
 collectgarbage()
  clear()
end


--------------------------------------------------------------------------------
--
-- The main VFD segments rendering function
-- segs is 8 bit, with a, b, c, d, e, f, g, dp from msb to lsb
-- digits is 9 bits, with S1 left, ..., S8/right, sign/left again, from msb to lsb
--
--------------------------------------------------------------------------------
function set( segs, digits )
  local data = bit.lshift( segs, 9 ) + digits
  for i = WORD_SIZE - 1, 0, -1 do
    pio.pin.setval( bit.isset( data, i ) and 1 or 0, din_pin )
    pio.pin.setval( 1, clk_pin )
    pio.pin.setval( 0, clk_pin )
  end
  pio.pin.setval( 1, load_pin )
  pio.pin.setval( 0, load_pin )
end



-- Turn off all segments of all digits
function clear()
--  set( 0x00, 0x00 )  This was the old implementation
-- Now we send only the 9 digit zeros for faster execution
  pio.pin.setval( 0, din_pin )
  for i = 1, 9 do
    pio.pin.setval( 1, clk_pin )
    pio.pin.setval( 0, clk_pin )
  end
  pio.pin.setval( 1, load_pin )
  pio.pin.setval( 0, load_pin )
end



-- Turn on all segments of all digits
function setall()
  set( 0xFF, 0x1FF )
end



-------------------------------------------------------------------------------
-- Now a primitive to write numbers, symbols and possible letters.
-- We left some examples here but only one setstring() should be needed.
-- They should simply return some data and let the caller program control
-- the needed multiplexing of the segments and digits buses or they could
-- possibly do this in a coroutine-coordinated manner. But we decided to keep
-- the multiplexing control on them to ilustrate and keep things simple. A loop
-- at the end of each function multiplexes the segs/digits control and a second
-- argument "time" in each function controls the limits of this loop.




-- This was the initial implementation to write numbers
-- Will probably be replaced by the setstring (further down) for better
-- performance. Although it works nice, setnum() has too much math operations
-- and doesn't write letters or symbols
function setnum( num, time )
  local nums = 
     { [ 0 ] = 0xFC, 0x60, 0xDA, 0xF2, 0x66, 0xB6, 0xBE, 0xE0, 0xFE, 0xE6 }
  local ndigits = mathmodf( mathlog10( num ) ) + 1  -- # of digits to write
  local t = {}
  for i = 1, ndigits do
    t[ i ] = nums[ mathfmod( num, 10 ) ]
    num = mathmodf( num / 10 )
  end
  for n = 1, time do
    for i = 1, ndigits do
      set( t[ i ], bit.bit( i - 1 ) )
    end
  end
end



-- This was the initial implementation to write "writeable" strings & numbers
-- It is simple and nice but it creates new strings when string.sub indexing
-- that become orphan, consuming RAM and triggering Garbage Collection sooner
-- or later.
function setstring1( str, time )
  for n = 1, time do
    for i = #str, 1, -1 do
      set( vfdc[ strsub( str, -i, -i ) ], bit.bit( i - 1 ) )
    end
  end
end



-- This is an attempt to substitute setstring1 (above) and avoid orphan strings
-- overproduction. It doesn't seem to be much slower and it index the segments
-- table by numbers (string.byte). Not sure yet if it is worth though ...
function setstring2( str, time )
  for n = 1, time do
    for i = #str, 1, -1 do
      set( vfdb[ strbyte( str, -i, -i ) ], bit.bit( i - 1 ) )
    end
  end
end 



-- This is like setstring1 but now Dots are processed to become part of the
-- preceding number digit and not ugly rendered on an independent digit.
function setstring3( str, time )
  local d = {}
  local di = 1
  local dotpending = false
  
  for i = 1, #str do
    local c = strsub( str, -i, -i )
    if c ~= "." then
      d[ di ] = vfdc[ c ]
      if dotpending then
        d[ di ] = d[ di ] + 0x01
        dotpending = false
      end
      di = di + 1
    else
      dotpending = true
    end
  end

  for n = 1, time do
    for i = #d, 1, -1 do
      set( d[ i ], bit.bit( i - 1 ) )
    end
  end

end




--------------------------------------------------------------------------------
--
-- The best current candidate for the setstring primitive
--
--------------------------------------------------------------------------------
function setstring( str, time )
  local d = {}                            -- Segments set/lit for each vfd digit
  local dotpending = false


  for i = 1, #str do
    local cb = strbyte( str, -i, -i )     -- character str.byte buffer
    if cb ~= 46 then                      -- 46 = string.byte(".") 
      d[ #d + 1 ] = vfdb[ cb ]
      if dotpending then
        d[ #d ] = d[ #d ] + 0x01          -- set bit0 for dot/dp
        dotpending = false
      end
    else
      dotpending = true
    end
  end
-- now multiplex/show the digits for some time  
  for n = 1, time do
    for i, v in ipairs( d ) do
      set( v, bit.bit( i - 1 ) )
    end
  end
end



--[[
-- ## Some future functions for when pwm is beeing used to control intensity
--    on the BLANK_PIN

function hide()
  pwm.setup( PWM_ID, PWM_CLK, 0 )
end



function show()
  pwm.setup( PWM_ID, PWM_CLK, PWM_DUTY )
end



function setintensity( duty )
  PWM_DUTY = duty
  pwm.setup( PWM_ID, PWM_CLK, PWM_DUTY )
end
--]]
