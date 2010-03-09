/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Felipe Maimon wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return.       Felipe Maimon
 * ----------------------------------------------------------------------------
 */


#ifndef _MAX6921_H_
#define _MAX6921_H_

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <stdint.h>

#define VFD_GRIDS			9			// How many grids in the VFD?
#define VFD_SEGS			8			// How many segments, each char
#define VFD_SPECIAL_CHAR	1			// How many grids with special chars
#define VFD_CHAR_BYTES		(((VFD_GRIDS + VFD_SEGS) / 8) + 1)
#define VFD_LAST_CHAR		(VFD_CHAR_BYTES - 1)

#define VFD_PORT			PORTB
#define VFD_DDR 			DDRB
#define VFD_LOAD			PB0
#define VFD_BLANK			PB1
#define VFD_DI				PB3
#define VFD_DO				PB4
#define VFD_CLK				PB5

// MAX6921 doesn't have a SS pin, but it is needed for SPI inside AVR
#define VFD_SS			PB2

/** Size of the circular receive buffer, must be power of 2 */
#define VFD_BUFFER_SIZE		16
#define VFD_BUFFER_MASK		( MAX_BUFFER_SIZE - 1)


// Don't use these two defines! Use the vfd_clear() or vfd_brightness() below
#define SET_BLANK	TCCR1A &= ~((1<<COM1A1) | (1<<COM1A0)); VFD_PORT |= (1<<VFD_BLANK)
#define SET_PWM		TCCR1A |= (1<<COM1A1) | (1<<COM1A0);

typedef union {
	struct {
		unsigned int grids:VFD_GRIDS;
		unsigned int segs :VFD_SEGS;
	};
	uint8_t bytes[VFD_CHAR_BYTES];
} vfd_char;



// Initialise  all the hardware and buffers 
void vfd_init(void);

// Stops the multiplexing action and set a single char in the display
void vfd_set(uint8_t segs, uint16_t grids);

// Clears the display using blank
#define vfd_clear() SET_BLANK

// Just a macro to display all segments in the VFD
#define vfd_setall() vfd_set(0xFF, 0x1FF)

// Sets the brightness of the VFD, by applying a PWM on blank pin
void vfd_brightness(uint8_t duty);

// Display a string of up to 16 char in the VFD
// Dots ('.') are not counted as the length, as it is integrated
// with the previous char.
// If string is empty (""), the last one stored in the buffer is used
// Strings are null (/0) terminated
void vfd_setstring(const char *str);

// Same as above, but the string is in the flash memory
void vfd_setstring_P(const char *str);

// Set the scroll speed. The parameter is the time it takes to scroll 1 char, in 
// multiples of 100 ms
void vfd_scrollspeed(uint8_t speed);

#endif
