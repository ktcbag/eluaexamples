#include <stdio.h>
#include <string.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "avrctypes.h"
#include "encoder.h"
#include "softuart.h"

/*
void reverse(char s[])
{
	u08 i, j;
	char c;

	for (i = 0, j = strlen(s)-1; i<j; i++, j--) {
		c = s[i];
		s[i] = s[j];
		s[j] = c;
	}
}



void itoa( s16 n, char s[])
{
	u08 i;
	u16 sign;

	if ((sign = n) < 0)
		n = -n;
	i = 0;
	do {
		s[i++] = n % 10 + '0';
	} while ((n /= 10) > 0);
	if (sign < 0)
		s[i++] = '-';
	s[i] = '\0';
	reverse(s);
}
*/

int main(){
	enc_init();
	softuart_init();
	sei();
	while(1){
		if( softuart_kbhit() ){
			char c = softuart_getchar();
			switch( c ){
				static s16 last_acc;
				char str[30];
				case 'l': 
					itoa( acc, str, 10 );
					softuart_puts( str );
					softuart_putchar( '\r' ); 
					softuart_putchar( '\n' ); 
					break;

				case 'r':
					itoa( acc - last_acc, str, 10 );
					softuart_puts( str );
					softuart_putchar( '\r' ); 
					softuart_putchar( '\n' ); 
					last_acc = acc;
					break;

				case 'c':
					acc = 0;
					last_acc = 0;
					break;
			}
		}
	}
}
