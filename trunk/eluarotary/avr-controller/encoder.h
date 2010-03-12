#ifndef __ENCODER_H
#define __ENCODER_H

#include <avr/io.h>
#include <avr/interrupt.h>
#include "avrctypes.h"

#define GLUE0( x, y )	x ## y
#define GLUE( x, y )	GLUE0( x, y )

#define ENC_PORT__	B
#define ENC_P0__	3
#define ENC_P1__	4

#define ENC_PORT	GLUE( PORT, ENC_PORT__ )
#define ENC_PIN		GLUE( PIN, ENC_PORT__ )
#define ENC_DDR		GLUE( DDR, ENC_PORT__ )

#define ENC_P0		GLUE( P, GLUE( ENC_PORT__, ENC_P0__ ) )
#define ENC_P1		GLUE( P, GLUE( ENC_PORT__, ENC_P1__ ) )

#define ENC_INT		ENC_P0
#define ENC_DIR		ENC_P1

volatile s16 acc;

static inline void enc_init( void ){
	ENC_DDR &= ~( ( 1 << ENC_DIR ) | ( 1 << ENC_INT ) ); // set as input
	ENC_PORT |= ( 1 << ENC_DIR ) | ( 1 << ENC_INT ); // set pull-up
	GIMSK |= ( 1 << PCIE ); // pin change interrupt enable
	PCMSK |= ( 1 << ENC_INT ); // pin that generates the interrupt
}

ISR( PCINT0_vect ){
	if( ENC_PIN & ( 1 << ENC_INT ) )
		acc += ( ENC_PIN & ( 1 << ENC_DIR ) ) ? 1 : -1;
	else
		acc += ( ENC_PIN & ( 1 << ENC_DIR ) ) ? -1 : 1;
}

#endif
