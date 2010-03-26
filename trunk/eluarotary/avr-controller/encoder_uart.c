#include <string.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "avrctypes.h"
#include "encoder.h"
#include "softuart.h"

int main( void ){
	char str[30];
	softuart_init();
	enc_init();
	sei();
	while(1){
		if( softuart_kbhit() ){
			char c = softuart_getchar();
			switch( c ){
				case 'l': 
					itoa( acc, str, 10 );
					softuart_puts( str );
					softuart_putchar( '\n' );
					break;

				case 'd':
					itoa( acc - last_acc, str, 10 );
					softuart_puts( str );
					softuart_putchar( '\n' );
					last_acc = acc; 
					break;
			}
		}
	}
}
