#include <string.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "avrctypes.h"
#include "encoder.h"
#include "usi2cs.h"

int main( void ){
	enc_init();
	usi2cs_init( 0x01 );
	sei();
	while(1){
		if( !cb_empty( &usi2cs.tx ) ){
			char c;
			cb_pop( &usi2cs.tx, &c );
			switch( c ){
				char str[30];
				case 'l': 
					itoa( acc, str, 10 );
					cb_pushstring( &usi2cs.tx, str );
					break;

				case 'd':
					itoa( last_acc, str, 10 );
					cb_pushstring( &usi2cs.tx, str );
					last_acc = acc; 
					break;
			}
		}
	}
}
