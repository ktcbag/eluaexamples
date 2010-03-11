------------------------------------------------
--
--   This is an example of how to communicate 
--   with a PS2 pc keyboard.
--   v0.1
------------------------------------------------

-- IO Pins connected to the keyboard
local P_CLK     = pio.pin.P0_1 -- Clock
local P_DATA    = pio.pin.P0_2 -- Data
local P_CLK_PD  = pio.pin.P0_3 -- Clock pull down
local P_DATA_PD = pio.pin.P0_4 -- Data pull down

function init()
  pio.pin.setdir( pio.OUTPUT, P_CLK_PD, P_DATA_PD )
end

function disable_communication()
  pio.pin.setval( 1, P_DATA_PD, P_CLK_PD )
end

function enable_communication()
  pio.pin.setval( 0, P_DATA_PD, P_CLK_PD )
end

function send( data )

end

function receive( timer, timeout )
  pio.pin.setdir( pio.INPUT, P_CLK, P_DATA )
  enable_communication()

  tmr.setclock( timer, 1000 )
  local tc = tmr.start( timer )

  local read = false

  -- Wait for the keyboard to begin to send, or timeout
  while not read do
    if pio.pin.getval( P_CLK ) == 0 and pio.pin.getval( P_DATA ) then
      read = true
    end

    tmr.read( timer )
    if tmr.read( timer ) == timeout + tc then
      return nil
    end
  end

  tmr.setclock( timer, 10000 )
  tc = tmr.start( timer )

  -- Wait for the clock to go Up or timeout
  while pio.pin.getval( P_CLK ) == 0 and tmr.read( timer ) - tc < 1 do
  end

  local data = 0
  -- Data is valid when Clock goes Down
  while tmr.read( timer ) - tc < 1 do
    if pio.pin.getval( P_CLK ) == 0 then
      tc = tmr.start( timer )
      data = bit.lshift( data, 1 )
      data = bit.bor( data, pio.pin.getval( P_DATA ) )
    end
    -- Check start bit, end bit, check bit
  end

end 
