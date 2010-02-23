--------------------------------------------------------------------------------
--
-- Some art effects and text writing to test eLua VFD module on IV-18 tubes
--
-- More info @ www.eluaproject.net
--
-- Dado Sutter, Fernando Araújo, Marcelo Politzer, Téo Benjamin
--
-- Fev 2010
--
--------------------------------------------------------------------------------


require("vfd")

vfd.init()

local LUAVERSION = string.upper( _VERSION )
-- local ELUAVERSION = "ELUA " .. elua.version()
local ELUAVERSION = "ELUA 0.7"



-- Upper counter right aligned
function num1()
  local n = 0
  repeat
    vfd.setstring( tostring( n ), 60 )
    if n <= 99999999 then
      n = n + 1
    else
      n = 0
    end
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end



-- Random 8 digit numbers right aligned
function num2()
  local n
  repeat
    n = math.random( 11111111, 99999999 )
    vfd.setstring( tostring( n ), 100 )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end
    


-- The number Pi with 7 decimals
function pi()
  local pi = string.format( "%1.7f", math.pi )
  vfd.setstring( pi, 1000 )
  vfd.clear()
end



-- The version number of eLua running on the platform
function eluaversion()
  vfd.setstring( ELUAVERSION, 1000 )
  vfd.clear()
end



-- The version number of Lua running on the platform
function luaversion()
  vfd.setstring( LUAVERSION, 1000 )
  vfd.clear()
end
    




                      ----- Auxiliary Functions -----

-- Adjust delay with terminal kbd keys
function handlekbd( k )
  if k == 119 then  -- k = w ?
    dly = dly + 20000
    print( "Current step delay = " .. dly .. "us" ) -- Print current delay in microseconds on terminal (for debugging)
  elseif k == 122 then  -- k = z ?
    dly = dly - 20000
    if dly < 0 then
      dly = 0
    end
    print( "Current step delay = " .. dly .. "us" ) -- Print current delay in microseconds on terminal (for debugging)
  end
end



