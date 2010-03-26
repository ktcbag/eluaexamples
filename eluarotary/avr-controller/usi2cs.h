#ifndef _USI2CS_H_
#define _USI2CS_H_

#include <avr/io.h>
#include <avr/interrupt.h>
#include "avrctypes.h"
#include "circularbuffer.h"

// DEVICE DEPENDENT
#define USI2CS_PORT_				B
#define USI2CS_SDA_					0
#define USI2CS_SCL_					2

#define USI2CS_START_vect			USI_START_vect
#define USI2CS_OVF_vect				USI_OVF_vect
// END OF DEVICE DEPENDENT

#define USI2CS_PORT					GLUE( PORT, USI2CS_PORT_ )
#define USI2CS_DDR 					GLUE( DDR, USI2CS_PORT_ )

#define USI2CS_SDA					GLUE( P, GLUE( USI2CS_PORT_, USI2CS_SDA_ ) )
#define USI2CS_SCL					GLUE( P, GLUE( USI2CS_PORT_, USI2CS_SCL_ ) )

#define usi2cs_state_stop			0
#define usi2cs_state_getaddr		1
#define usi2cs_state_send			4
#define usi2cs_state_recv			5
#define usi2cs_state_ackrecv		6
#define usi2cs_state_acksend		7
#define usi2cs_state_ackrecvdone 	8

#define USI2CS_ACKRECV				0
#define USI2CS_ACKSEND				1

struct usi2cs{
	volatile u08 addr;
	volatile u08 state;
	struct cb tx, rx;
} usi2cs;


static void usi2cs_init( u08 addr );
static void usi2csh_setupusi( void );
static void usi2csh_ack( u08 send ); // 1 to send, 0 to recv
static void usi2csh_readdata( void );
static void usi2csh_writedata( void );

static void usi2cs_init( u08 addr ){
	usi2cs.addr = addr;
	usi2csh_setupusi();
	cb_init( &usi2cs.tx );
	cb_init( &usi2cs.rx );
}

static void usi2csh_setupusi( void ){
	USICR =		( 1 << USISIE )|	// start cond int
				( 0 << USIOIE )|	// start cond will enable ovf int
				( 1 << USIWM1 )|	// 2-wire mode
				( 1 << USIWM0 )|	// wait slave ready
				( 1 << USICS1 )|	// external clk
				( 1 << USICS0 )|	// positive edge
				( 0 << USICLK );	// 4-bit counter inc

	USI2CS_DDR &=  ~( ( 1 << USI2CS_SDA )| // set both in
					  ( 1 << USI2CS_SCL ));
	USI2CS_PORT |=  ( 1 << USI2CS_SDA )| // set both high
					( 1 << USI2CS_SCL );
}

ISR( USI2CS_START_vect ){
	USI2CS_DDR &= ~( 1 << USI2CS_SDA );	// set as input
	USICR =	( 0 << USISIE )|			// start cond int
			( 1 << USIOIE )|			// start cond will enable ovf int
			( 1 << USIWM1 )|			// 2-wire mode
			( 1 << USIWM0 )|			// wait slave ready
			( 1 << USICS1 )|			// external clk
			( 1 << USICS0 )|			// positive edge
			( 0 << USICLK )|			// 4-bit counter inc
			( 0 << USITC );
	USISR = ( 1 << USIOIF  )|			// clear ovf int
			( 0 << USICNT0 );			// clear 4-bit counter
	usi2cs.state = usi2cs_state_getaddr;
}

ISR( USI2CS_OVF_vect ){ // over flow vector
	if( USISR & ( 1 << USIPF ) ) // stop bit
		usi2cs.state = usi2cs_state_stop;
	switch( usi2cs.state ){
		case usi2cs_state_getaddr:
			if( usi2cs.addr == ( USIDR >> 1 ) ){
				usi2csh_ack( USI2CS_ACKSEND );
				usi2cs.state = ( USIDR & 0x01 ) ? usi2cs_state_recv : usi2cs_state_send;
			}
			else // get ready for next start
				usi2csh_setupusi();
			break;
////////////////////////////////Read///////////////////////////////
		case usi2cs_state_recv:
			usi2csh_readdata();
			usi2cs.state = usi2cs_state_ackrecv;
			break;
		case usi2cs_state_acksend: // get data and send ack
			cb_push( &usi2cs.rx, USIDR );
			usi2csh_ack( USI2CS_ACKSEND );
			usi2cs.state = usi2cs_state_recv;
			break;
////////////////////////////////Write//////////////////////////////
		case usi2cs_state_send:
			if( !( USIDR & 1 ) ){ // didnt received ack
				usi2csh_setupusi();
			}
			usi2csh_writedata();
			usi2cs.state = usi2cs_state_ackrecv;
			break;
		case usi2cs_state_ackrecv: // send data and check ack
			cb_pop( &usi2cs.tx, (char*) &USIDR );
			usi2csh_ack( USI2CS_ACKRECV );
			usi2cs.state = usi2cs_state_send;
			break;
///////////////////////////////////////////////////////////////////
		case usi2cs_state_stop:
		default:
			usi2csh_setupusi();
			break;
	}
}

static void usi2csh_readdata( void ){
	USI2CS_DDR &= ~( 1 << USI2CS_SDA );	// set as input
	USISR = ( 0 << USISIE )|
			( 1 << USIOIF )|
			( 1 << USIPF )|
			( 1 << USIDC )|
			( 0x0 << USICNT0 );			// count 8 bits
}

static void usi2csh_writedata( void ){
	USI2CS_DDR |= ( 1 << USI2CS_SDA );	// set as output
	USISR = ( 0 << USISIE )|
			( 1 << USIOIF )|
			( 1 << USIPF )|
			( 1 << USIDC )|
			( 0x0 << USICNT0 );			// count 8 bits
}

static void usi2csh_ack( u08 send ){
	if( send )
		USI2CS_DDR |=  ( 1 << USI2CS_SDA ); // send
	else
		USI2CS_DDR &= ~( 1 << USI2CS_SDA ); // recv
	USISR = ( 0 << USISIF )|
			( 1 << USIOIF )|
			( 1 << USIPF )|
			( 1 << USIDC )|
			( 0x0E << USICNT0 ); // one bit shift
}

#endif
