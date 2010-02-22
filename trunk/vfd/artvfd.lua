--------------------------------------------------------------------------------
--
-- Some art effects to test eLua VFD module on IV-18 tubes
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



-- Blink all segments of all digits
function blinkall()
  local k
  dly = 160000
  repeat
    vfd.setall()
    tmr.delay( 1, dly )
    vfd.clear()
    tmr.delay( 1, dly )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
end
  


-- Wide dashes going up & down
function art1()
  local k
  dly = 100000
  repeat
    for i = 0, 7 do
      vfd.set( 0x60, bit.bit( i ) )    
      tmr.delay( 1, dly )
    end
    for i = 7, 1, -1 do
      vfd.set( 0x60, bit.bit( i ) )    
      tmr.delay( 1, dly )
    end
    vfd.clear()
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
end



-- Wide dashes going up and paralell dashes comming down
function art2()
  local k
  dly = 100000
  repeat
    for i = 0, 7 do
      vfd.set( 0x60, bit.bit( i ) )    
      tmr.delay( 1, dly )
    end
    vfd.set( 0x02, 0x100 )
    tmr.delay( 1, dly )
    for i = 6, 1, -1 do
      vfd.set( 0x90, bit.bit( i ) )    
      tmr.delay( 1, dly )
    end
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end



-- As art2() but digits are kept lit while going up or down
function art3()
  local v
  local k
  dly = 100000
  repeat
    v = 0
    for i = 0, 7 do
      v = bit.bor( bit.bit( i ), v )
      vfd.set( 0x60, v )
      tmr.delay( 1, dly )
    end
    v = 0
    for i = 7, 0, -1 do
      v = bit.bor( bit.bit( i ), v )
      vfd.set( 0x90, v )
      tmr.delay( 1, dly )
    end
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end



-- Vertical dashes dancing
function art4()
  local k
  dly = 200000
  repeat
    vfd.set( 0x02, 0x55 )
    tmr.delay( 1, dly )
    vfd.set( 0x02, 0xAA )
    tmr.delay( 1, dly )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end



-- A dash going all arround the digits' edges
function art5()
  local k
  dly = 100000
  repeat
    for i = 0, 7 do
      vfd.set( 0x10, bit.bit( i ) )    
      tmr.delay( 1, dly )
    end
    vfd.set( 0x08, 0x80 )
    tmr.delay( 1, dly )
    vfd.set( 0x04, 0x80 )
    tmr.delay( 1, dly )
    for i = 7, 0, -1 do
      vfd.set( 0x80, bit.bit( i ) )    
      tmr.delay( 1, dly )
    end
    vfd.set( 0x40, 0x01 )
    tmr.delay( 1, dly )
    vfd.set( 0x20, 0x01 )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end
  


-- A dash going all arround the digits' edges and centers
function art6()
  local k
  dly = 100000
  repeat
    for i = 0, 7 do                     -- go up on left
      vfd.set( 0x10, bit.bit( i ) )    
      tmr.delay( 1, dly )
    end
    vfd.set( 0x08, 0x80 )               -- go right 1 on up
    tmr.delay( 1, dly )
    for i = 7, 0, -1 do                 -- go down on middle
      vfd.set( 0x02, bit.bit( i ) )
      tmr.delay( 1, dly)
    end
    vfd.set( 0x40, 0x01 )               -- go right 2 on bottom
    tmr.delay( 1, dly )
    for i = 0, 7 do                    -- go up on right
      vfd.set( 0x80, bit.bit( i ) )    
      tmr.delay( 1, dly )
    end
    vfd.set( 0x04, 0x80 )               -- go left 2 on up
    tmr.delay( 1, dly )
    for i = 7, 0, -1 do                 -- go down on middle
      vfd.set( 0x02, bit.bit( i ) )
      tmr.delay( 1, dly)
    end
    vfd.set( 0x20, 0x01 )               -- go left 1 on bottom
    tmr.delay( 1, dly )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end
  


-- Show simultaneously each possible segment in a different digit
function art7()
  repeat
    for i = 0, 7 do
      vfd.set( bit.bit(i), bit.bit(i) )
    end
    vfd.set ( 0x03, 0x100 )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end



-- Bubbles going "up" in random side positions
function bubble1()
  local k
  local t = { 0x3A, 0xC6 }
--  bl = 0x3A -- bubble left, the lower round of a digit
--  br = 0xC6 -- bubble right, the upper round of a digit
  dly = 80000
  repeat
    for i = 0, 7 do
      vfd.set( t[ math.random( 1, 2 ) ], bit.bit( i ) )
      tmr.delay( 1, dly )
    end
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end  
  

  
-- Bubles on random sides and on random digit positions  
function bubble2()
  local k
  local t = { 0x3A, 0xC6 }
--  bl = 0x3A -- bubble left, the lower round of a digit
--  br = 0xC6 -- bubble right, the upper round of a digit
  dly = 200000
  repeat
    vfd.set( t[ math.random( 1, 2 ) ], math.random( 1, 0xFF ) )
    tmr.delay( 1, dly )  
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end  
  
  

-- Random seg pattern in a random digit position
function random1()
  local k
  dly = 400000
  repeat
    vfd.set( math.random( 0, 0xFF ), bit.bit( math.random( 0, 7 ) ) )
    tmr.delay( 1, dly )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end



-- Random seg patterns in random digit positions  
function random2()
  local k
  dly = 400000
  repeat
    vfd.set( math.random( 0, 0xFF ), math.random( 0, 0x1FF ) )
    tmr.delay( 1, dly )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end



-- One dot, bouncing between the edges
function dots1()
  local k
  dly = 100000
  repeat
    for i = 0, 7 do
      vfd.set( 0x01, bit.bit( i ) )
      tmr.delay( 1, dly )
    end
    for i = 8, 1, -1 do
      vfd.set( 0x01, bit.bit( i ) )
      tmr.delay( 1, dly )
    end
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end



-- One dot at a random digit position
function dots2()
  local k
  dly = 200000
  repeat
    vfd.set( 0x01, bit.bit( math.random( 0, 8 ) ) )
    tmr.delay( 1, dly )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end
  


-- Random number of dots at random digits positions
function dots3()
  local k
  dly = 200000
  repeat
    vfd.set( 0x01, math.random( 0, 0x1FF ) )
    tmr.delay( 1, dly )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end



-- eLua written statically in the middle
function elua1()
  local k
  local e = 0x9E
  local l = 0x1C
  local u = 0x7C
  local a = 0xEE
  repeat
    vfd.set( e, 0x20 )
    vfd.set( l, 0x10 )
    vfd.set( u, 0x08 )
    vfd.set( a, 0x04 )
    k = term.getchar( term.NOWAIT )
    handlekbd( k )
  until k == term.KC_ESC
  vfd.clear()
end  



-- eLua scrolls in both directions
function elua2()
  local k
  local e = 0x9E
  local l = 0x1C
  local u = 0x7C
  local a = 0xEE
  repeat
    for i = 3, 6 do
      for j = 1, 30 do
        vfd.set( e, bit.bit( i ) )
        vfd.set( l, bit.bit( i - 1 ) )
        vfd.set( u, bit.bit( i - 2 ) )
        vfd.set( a, bit.bit( i - 3 ) )
      end
      k = term.getchar( term.NOWAIT )
      handlekbd( k )
    end
    for i = 7, 4, -1 do
      for j = 1, 30 do
        vfd.set( e, bit.bit( i ) )
        vfd.set( l, bit.bit( i - 1 ) )
        vfd.set( u, bit.bit( i - 2 ) )
        vfd.set( a, bit.bit( i - 3 ) )
      end
      k = term.getchar( term.NOWAIT )
      handlekbd( k )
    end
  until k == term.KC_ESC
  vfd.clear()
end  



-- Letters comming one by one from right to left
function elua3()
  local k
  local t = { 0x9E, 0x1C, 0x7C, 0xEE }  -- ELUA chars on IV-18 VFD
  while true do
    for i = 0, 35 do -- 26 is enough, 35 adds some extra time at the end
      for j = 1, 10 do
        vfd.set( t[ 1 ], bit.bit( math.min( i, 7 ) ) )
        vfd.set( t[ 2 ], bit.bit( math.min( i - 8, 6 ) ) )
        vfd.set( t[ 3 ], bit.bit( math.min( i - 15, 5 ) ) )
        vfd.set( t[ 4 ], bit.bit( math.min( i - 21, 4 ) ) )
      end
      k = term.getchar( term.NOWAIT )
      handlekbd( k )
      if k == term.KC_ESC then
        vfd.clear()
        return
      end
    end
  end
end  




                      ----- Auxiliar Functions -----

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



