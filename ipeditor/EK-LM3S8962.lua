local pio = pio
  
module(..., package.seeall)

BTN_UP      = pio.PE_0
BTN_DOWN    = pio.PE_1
BTN_LEFT    = pio.PE_2
BTN_RIGHT   = pio.PE_3
BTN_SELECT  = pio.PF_1

btn_pressed = function( button )
  if pio.pin.getval( button ) == 1 then return false end
  tmr.delay( 0, 80000 )
  return pio.pin.getval( button ) == 0
end

LED_1 = pio.PF_0

pio.pin.setdir( pio.INPUT, BTN_UP, BTN_DOWN, BTN_LEFT, BTN_RIGHT, BTN_SELECT )
pio.pin.setpull( pio.PULLUP, BTN_UP, BTN_DOWN, BTN_LEFT, BTN_RIGHT, BTN_SELECT )
pio.pin.setdir( pio.OUTPUT, LED_1 )

