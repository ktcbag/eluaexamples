--Lua control for xbeePRO in API mode
local uart_id = 0
local uart_baud = 9600
local platform = require( pd.board() )
local modem_reset = { 0x00, 0x02, 0x8a, 0x00, 0x75 }    --modem status "Reset" frame including checksum
--lm3s.disp.init( 1000000 )
xbee_reset = pio.P#_#   --pin that is connected to reset pin of xbee
pio.pin.sethigh( xbee_reset )
transmit_request_16 = 0x01
transmit_request_64 = 0x00
frame_delimiter = 0x7E

function xbee.init( uart_id, uart_baud )
  uart.setup( 1, 9600, 8, uart.PAR_NONE, uart.STOP_1 )
  pio.pin.setlow( xbee_reset )    --reset xbee module
  tmr.delay( 0, 200 )
  pio.pin.sethigh( xbee_reset )

  while ( i < 1000) do --read 100 times the usart
    uart_data =  uart.getchar( uartid, uart.NO_TIMEOUT )
    if ( uart_data == 0x7e) then
      break   --if data recieved equals to frame delimiter (0x7e) then break
    end
  end

  if( art_data ~= 0x7e ) then   --fail if no frame delimiter was received. Typical reset time is 300ms
    return( false )
  end
  i = 0
  while( i < 5 ) do
    uart_data =  uart.getchar( uartid, uart.NO_TIMEOUT )
    if( uart_data ~= "") then
      modem_receive[ i ] = uart_data
      i++
    end
  end

  for i in ipairs( modem_reset ) do
    if( modem_receive[ i ] ~= modem_reset[ i ] ) then   --if received packet isn't modem status "Reset" 
      return( false )
    end
  end
  return( true )
end



function xbee_transmit_16( uart_id, number_of_bytes_of_adress, adress, nbytes, data, frame_id, options)
  uart.write( uart_id, frame_delimiter )    --send frame delimiter

  if( number_of_bytes_of_adress == 16 ) then
    length = nbytes + 5    --data plus frame type, frame ID, addr, options
    length_msb = bit.rshift( length, 8 )
    length_lsb = bit.band( length, 0x00FF )
    uart.write( uart_id, length_msb, lenght_lsb, transmit_request_16, frame_id )    --send length, frame type and frame ID
    adress_msb = bit.rshift( adress, 8 )
    adress_lsb = bit.band( adress, 0x00FF )
    uart.write( uart_id, adress_msb, adress_lsb )    --send adress    checksum = transmit_request_16 + frame_id + adress  --starting calculating checksum from here

  else if( number_of_bytes_of_adress == 64 ) then
    length = nbytes + 11    --data plus frame type, frame ID, addr, options
    length_msb = bit.rshift( length, 8 )
    length_lsb = bit.band( length, 0x00FF )
    uart.write( uart_id, length_msb, lenght_lsb, transmit_request_64, frame_id )    --send length, frame type and frame ID
    adress_byte_1 = bit.rshift( adress, 24 )
    adress_byte_2 = bit.rshift( bit.band( adress, 0x00FF000000000000 ), 6 )
    adress_byte_3 = bit.rshift( bit.band( adress, 0x0000FF0000000000 ), 5 )
    adress_byte_4 = bit.rshift( bit.band( adress, 0x000000FF00000000 ), 4 )
    adress_byte_5 = bit.rshift( bit.band( adress, 0x00000000FF000000 ), 3 )
    adress_byte_6 = bit.rshift( bit.band( adress, 0x0000000000FF0000 ), 2 )
    adress_byte_7 = bit.rshift( bit.band( adress, 0x000000000000FF00 ), 1 )
    adress_byte_8 = bit.band( adress, 0x00000000000000FF )
    uart.write( uart_id, adress_byte_1, adress_byte_2, adress_byte_3, adress_byte_4 )   --send adress
    uart.write( uart_id, adress_byte_5, adress_byte_6, adress_byte_7, adress_byte_8 )   --send adress      checksum = transmit_request_64 + frame_id   --starting calculating checksum from here0

  else
    print( "Error, wrong number of bytes of adress. Use 16 or 64 bits" )
    return false
  end

  uart.write( uart_id, options )    --send options
  for i = 0; i < nbytes; i++ do
    uart.write( uart_id, data[ i ] )    --send data
  end  checksum = 	0xff - checksum
  uart.write( uart_id, checksum )
  return true
end


--[[function send_bin( uart_id, string )
  for i in ipairs( string ) do
    if ( string[ i ] > 47 and string[ i ] < 58 ) then
      string[ i ] = string[ i ] - 48
    else if ( string[ i ] > 64 and string[ i ] < 71 ) then
      string[ i ] = string[ i ] - 55
    else if ( string[ i ] > 96 and string[ i ] < 103 ) then
      string[ i ] = string[ i ] - 87
    end
    uart.write( uart_id, string[ i ] )
  end
end
--]]


	uart.setup( 1, 9600, 8, uart.PAR_NONE, uart.STOP_1 )
    
	while uart.getchar( uartid, uart.NO_TIMEOUT ) == "" do
		if platform.btn_pressed( platform.BTN_UP ) then
			uart.write( 1, "liga", '\r' )
			tmr.delay( 1, 600000 )
		end
		if platform.btn_pressed( platform.BTN_DOWN ) then
			uart.write( 1, "desliga", '\r' )
			tmr.delay( 1, 600000 )
		end
	end
