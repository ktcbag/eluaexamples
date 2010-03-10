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
