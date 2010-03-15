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
  pio.pin.setdir( pio.INPUT, P_CLK, P_DATA )
end

function disable_communication()
  pio.pin.setval( 1, P_CLK_PD )
  tmr.delay( timer, 110 ) -- Min 100 us
end

function enable_communication()
  pio.pin.setval( 0, P_CLK_PD )
end

function request_send()
  pio.pin.setval( 1, P_DATA_PD )
end

function parity( data )
  local count = 0

  for i= 1, 8 do
    if bit.isset( data, i ) then
      count = count + 1
    end
  end

  return bit.bnot( bit.band( data, 1 ) )

  --[[
  if bit.band( data, 1 ) ~= parity then
    return true
  else
    return false
  end
  --]]
end

function send( data, timer )
  -- Request send
  disable_communication()
  request_send()
  enable_communication()

  local c            -- Temporary: Current char
  local qtd = #data  -- Data length

  for cur = 1, qtd do
    -- Get current char code
    c = string.byte( string.sub( data, cur, cur ) )

    -- Send data
    for bit = 1, 8 do  
      -- Wait for device to clock to send Data
      while pio.pin.getval( P_CLK ) ~= 0 do
      end

      -- Put data bit
      pio.pin.setval( bit.isclear( c, bit ), P_DATA_PD ) -- Inverted ( pull down )

      -- Wait for clock to get high
      while pio.pin.getval( P_CLK ) ~= 1 do
      end
    end

    -- Send parity bit
      -- Wait for device to clock to send Data
      while pio.pin.getval( P_CLK ) ~= 0 do
      end

      -- Put parity bit
      pio.pin.setval( bit.bnot( parity( c ) ), P_DATA_PD ) -- Inverted ( pull down )

      -- Wait for clock to get high
      while pio.pin.getval( P_CLK ) ~= 1 do
      end

    -- Stop bit 
    pio.pin.setval( 0, P_DATA_PD )

    -- Wait for acknowledge bit
      -- Wait for the device to bring Data low
      while pio.pin.getval( P_DATA ) ~= 0 do
      end

      -- Wait for the device to bring Clock low
      while pio.pin.getval( P_CLK ) ~= 0 do
      end

      -- Wait for the device to release Data and Clock
      while pio.pin.getval( P_CLK ) ~= 1 or pio.pin.getval( P_DATA ) ~= 1 do
      end
  end
end

function receive( timer, timeout )
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

  local data_in = 0
  local data_out = ""
  local bits_read = 0
  
  -- Data is valid when Clock goes Down
  while tmr.read( timer ) - tc < 1 do
    if pio.pin.getval( P_CLK ) == 0 then
      tc = tmr.start( timer )
      data_in = bit.lshift( data_in, 1 )
      datain = bit.bor( datain, pio.pin.getval( P_DATA ) )
      bits_read = bits_read + 1
    end

    -- Check start bit, end bit, check bit
    if bits_read == 11 and bit.isset( data_in, 11 ) then -- Start bit 
      -- If its not 0, something is wrong, clear the bit and ignore
      bits_read = 10
      data_in = bit.clear( data_in, 11 )
    end

    if bits_read == 11 not bit.isset( data_in, 1 ) then -- Stop bit
      -- If its not 1, something is wrong, ignore
      bits_read = 10
    end

    if bits_read == 11 and check_parity( bits_read ) ~= bit.band( data_in, 2^9 ) then -- Parity
      send_invalid_command()
      bits_read == 0
    end

    if bits_read == 11 then -- Everithing OK
      -- Clear bit counter
      bits_read = 0

      -- Remove extra bits
      data_in = bit.clear( data_in, 1, 10, 11 )
      data_in = bit.rshift( data_in, 2 )

      -- Add the received data to the message buffer
      data_out = data_out .. data_in
    end
  end

  return data_out
end 

