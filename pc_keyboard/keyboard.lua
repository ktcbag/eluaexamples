--------------------------------------------------
--
--   This is an example of how to communicate 
--   with a PS2 pc keyboard.
--   v0.1
--
--   by Thiago Naves, Led Lab, PUC-Rio, march 2010
--
--------------------------------------------------

-- IO Pins connected to the keyboard
--  LM3S
--[[
local P_CLK     = pio.PC_7 -- Clock
local P_DATA    = pio.PC_5 -- Data
local P_CLK_PD  = pio.PG_0 -- Clock pull down
local P_DATA_PD = pio.PA_7 -- Data pull down
--]]

-- MBED
P_CLK     = mbed.pio.P18 -- Clock
P_DATA    = mbed.pio.P10 -- Data
P_CLK_PD  = mbed.pio.P19 -- Clock pull down
P_DATA_PD = mbed.pio.P11 -- Data pull down

function init()
  pio.pin.setdir( pio.OUTPUT, P_CLK_PD, P_DATA_PD )
  pio.pin.setdir( pio.INPUT, P_CLK, P_DATA )
  pio.pin.setval( 1, P_DATA_PD, P_CLK_PD )
end

function disable_communication( timer )
  pio.pin.setval( 0, P_CLK_PD )
  tmr.delay( timer, 110 ) -- Min 100 us
end

function enable_communication()
  pio.pin.setval( 1, P_CLK_PD )
end

function request_send()
  pio.pin.setval( 0, P_DATA_PD )
end

function parity( data )
  local count = 0

  for i= 1, 8 do
    if bit.isset( data, i ) then
      count = count + 1
    end
  end

  return bit.bnot( bit.band( data, 1 ) )
end

function send( data, timer )
  -- Request send
  disable_communication( timer )
  request_send()
  enable_communication()

  local c            -- Temporary: Current char
  local qtd = #data  -- Data length

  for cur = 1, qtd do
    -- Get current char code
    c = string.byte( string.sub( data, cur, cur ) )

    -- Send data
    for cbit = 1, 8 do  
      print( "  Bit: " .. cbit )

      -- Wait for device to clock to send Data
      while pio.pin.getval( P_CLK ) ~= 1 do
      end

      -- Put data bit
      if bit.isset( c, cbit ) then
        pio.pin.setval( 0, P_DATA_PD )
      else
        pio.pin.setval( 1, P_DATA_PD )
      end

      -- Wait for clock to get high
      while pio.pin.getval( P_CLK ) ~= 0 do
      end

      print( "- Bit: " .. cbit )
    end

    -- Send parity bit
      -- Wait for device to clock to send Data
      while pio.pin.getval( P_CLK ) ~= 1 do
      end

      -- Put parity bit
      if parity( c ) == 1 then
        pio.pin.setval( 0, P_DATA_PD )
      else
        pio.pin.setval( 1, P_DATA_PD )
      end

      -- Wait for clock to get high
      while pio.pin.getval( P_CLK ) ~= 0 do
      end

    -- Stop bit 
    pio.pin.setval( 0, P_DATA_PD )

    -- Wait for acknowledge bit
      -- Wait for the device to bring Data low
      while pio.pin.getval( P_DATA ) ~= 1 do
      end

      -- Wait for the device to bring Clock low
      while pio.pin.getval( P_CLK ) ~= 1 do
      end

      -- Wait for the device to release Data and Clock
      while pio.pin.getval( P_CLK ) ~= 0 or pio.pin.getval( P_DATA ) ~= 0 do
      end
  end
end

function receive()
  enable_communication()

  -- local count = 0
  local data = 0
  -- local data_out = ""
  
  for i = 1, 11 do
    while pio.pin.getval( P_CLK ) ~= 1 do -- Wait for next clock
    end

    if i < 11 then
      while pio.pin.getval( P_CLK ) ~= 0 do -- Wait for clock to go low
      end
    end

    data = bit.rshift( data, 1 )

    if pio.pin.getval( P_DATA ) == 1 then -- Inset the read bit
      data = bit.bor( data, bit.bit( 10 ) )
    end

    print( i )
  end

  return data
end
