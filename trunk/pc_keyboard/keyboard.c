#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "platform.h"
#include "auxmods.h"
#include "lrotable.h"
#include "platform_conf.h"
#include <string.h>

#define MIN_OPT_LEVEL 2
#include "lrodefs.h"

#define DIR_OUT 0
#define DIR_IN 1

#define IGNORE 1
#define USE 0

#define ERROR 0

#define ACK 0xFA
#define SETLEDS 0xED
#define ECHO 0xEE

typedef struct sPin
{
  pio_type pin, port;
} tPin;

/* Pin Configuration */
tPin P_CLK, P_DATA, P_CLK_PD, P_DATA_PD;

/* Start, Stop and Parity bits ignore configuration */
char igStart = USE;
char igStop = USE;
char igParity = USE;

/* Converts a pin number got from the Lua stack to the tPin format */
static tPin convertPin( int p )
{
  tPin result;
  result.port = PLATFORM_IO_GET_PORT( p );
  result.pin = ( 1 << PLATFORM_IO_GET_PIN( p ) );

  return result;
}

/* Just to make the code easier to read */
/* Sets a pin value ( 1 / 0 ) */
static void setPinVal( tPin p, char val )
{
  if ( val )
    platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_SET );
  else
    platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_CLEAR );
}

/* Just to make the code easier to read */
/* Sets a pin direction ( DIR_IN / DIR_OU ) */
static void setPinDir( tPin p, char dir )
{
  if ( dir == DIR_IN )
    platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_DIR_INPUT );
  else
    platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_DIR_OUTPUT );
}

/* Just to make the code easier to read */
/* Returns the current pin value */
static int getPinVal( tPin p )
{
  return platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_GET );
}

/* Generates a Parity bit for a given char ( to send data ) */
static char genCRC( unsigned char data )
{
  int i, count;

  count = 0;

  /* Count the 1s */
  for ( i=0; i<8; i++ )
  {
    if ( ( data & 1 ) == 1 )
      count ++;

    data = data >> 1;
  }

  /* The parity bit is set if there is an even number of 1s  */
  return ( ( count & 1 ) != 1 );
}

/* Checks the Parity bit for a given package */
static char checkCRC( unsigned int data )
{
  /* Checks the parity bit ( odd parity ) */
  unsigned int tmp;
  int i, count;

  count = 0;
  tmp = data;

  /* Extract data bits */
  data = data >> 1;
  data = data & 255;

  /* Count the 1s */
  for ( i=0; i<8; i++ )
  {
    if ( ( data & 1 ) == 1 )
      count ++;

    data = data >> 1;
  }

  /* The parity bit is set if there is an even number of 1s  */
  return ( ( count & 1 ) != ( tmp & 512 ) );
}

/* Set IGNORE flags for Start, Stop and/or Parity bits */
/* This is due to buggy keyboards */
static int keyboard_setflags( lua_State *L )
{ 
  /* Start, Stop, Parity */
  /* Set ignore bits flags */
  if ( luaL_checkinteger( L, 1 ) )
    igStart = IGNORE;
  else
    igStart = USE;

  if ( luaL_checkinteger( L, 2 ) )
    igStop = IGNORE;
  else
    igStop = USE;

  if ( luaL_checkinteger( L, 3 ) )
    igParity = IGNORE;
  else
    igParity = USE;

  return 0;
}

/* Initializes pin directions and default values */
static int keyboard_init( lua_State *L )
{
  P_CLK = convertPin( luaL_checkinteger( L, 1 ) );
  P_DATA = convertPin( luaL_checkinteger( L, 2 ) );
  P_CLK_PD = convertPin( luaL_checkinteger( L, 3 ) );
  P_DATA_PD = convertPin( luaL_checkinteger( L, 4 ) );
  setPinDir( P_CLK_PD, DIR_OUT );
  setPinDir( P_DATA_PD, DIR_OUT );
  setPinDir( P_DATA, DIR_IN );
  setPinDir( P_CLK, DIR_IN );

  setPinVal( P_DATA_PD, 1 );
  setPinVal( P_CLK_PD, 1 );

  return 0;
}

static int keyboard_clk( lua_State *L )
{
  pio_type port, pin;
  int p;

  // get pin.
  p = luaL_checkinteger( L, 1 );
  // validade
  port = PLATFORM_IO_GET_PORT( p );
  pin = PLATFORM_IO_GET_PIN( p );

  if( PLATFORM_IO_IS_PORT( p ) ||
      !platform_pio_has_port( port ) ||
      !platform_pio_has_pin( port, pin ) )
  {
    return luaL_error( L, "pin selection error" );
  }

  platform_pio_op( port, 1 << pin, PLATFORM_IO_PIN_DIR_OUTPUT );

  while ( 1 )
  {
     platform_pio_op( port, 1 << pin, PLATFORM_IO_PIN_SET );
     platform_pio_op( port, 1 << pin, PLATFORM_IO_PIN_CLEAR );
  }
  return 0;
};

/* Receives a char from the keyboard */
static char keyboard_getchar( )
{
  unsigned int data = 0;

  int i;
  for ( i=1; i<12; i++ )
  {
    while ( getPinVal( P_CLK ) != 1 ) /* Wait for next clock */
    {}

    if ( i < 11 )
      while ( getPinVal( P_CLK ) ) /* Wait for clock to go low */
      {}

    data = data >> 1;

    if ( getPinVal( P_DATA ) == 1 )
      data = data | ( 1 << 10 );
  }

  /* Check start bit */
  if ( ( ( data & 1 ) == 1 ) && ( igStart == USE ) )
    return ERROR;

  /* Check stop bit ( com problema )*/
  if ( ( ( data & 1024 ) == 0 ) && ( igStop == USE ) )
    return ERROR;

  /* Check CRC bit */
  if ( ( checkCRC( data ) == 0 ) && ( igParity == USE ) )
    return ERROR;

  /* Remove Start, Stop and CRC bits */
  data = data >> 1;
  data = data & 255;

  return data;
}

/* Wrapper ( bind ) for keyboard_getchar function */
static int keyboard_receive( lua_State *L )
{
  lua_pushinteger( L, keyboard_getchar () );
  return 1;
}

/*
static int keyboard_read( lua_State *L )
{
  char c;
  int qtd = 0;

  while ( 1 )
  {
    c = keyboard_getchar();

    if ( c == 28 )
      lua_pushchar( "a" )
      printf( "a" );
    else
      if ( c == 50 )
         printf( "b" );
  }

  printf( "\n" );
  return 0;
}
*/

/* Sends data to the keyboard */
static void keyboard_write( char data )
{
  char bit; /* Counter */
  char par = genCRC( data ); /* Parity Bit */

  
  /* Disable communication & Request Send */
  setPinVal( P_CLK_PD, 0 );
  platform_timer_delay( 1, 120 ); /* 120 microseconds */
  setPinVal( P_DATA_PD, 0 );
  setPinVal( P_CLK_PD, 1 );

  /* Wait for clock and send data */
  for ( bit=1; bit<= 11; bit++ )
  {
    while ( getPinVal( P_CLK ) == 1 )
    {}

    if ( bit == 9 ) /* Parity Bit */
      setPinVal( P_DATA_PD, par );
    else
      if ( bit == 10 ) /* Stop Bit */
        setPinVal( P_DATA_PD, 1 );
      else
        if ( bit != 11 ) /* Data Bit */
          setPinVal( P_DATA_PD, data & ( 1 << ( bit -1 ) ) );

    /* bit == 11 -> ACK bit, just ignore it */

    while ( getPinVal( P_CLK ) == 0 )
    {}
  }
}

/* Bind to keyboard_write function */
/* Sends a byte to the Keyboard */
static int keyboard_send( lua_State *L )
{
  int i;
  i = luaL_checkinteger( L, 1 );
  keyboard_write( i );
  return 0;
}

/* Sets the Num Lock, Caps Lock and Scroll Lock Leds state */
static int keyboard_setleds( lua_State *L )
{
  int i = 0;
  i = i | ( luaL_checkinteger( L, 1 ) << 1 ); /* Num Lock */
  i = i | ( luaL_checkinteger( L, 2 ) << 2 ); /* Caps Lock */
  i = i | ( luaL_checkinteger( L, 3 ) ); /* Scroll Lock */

  keyboard_write( SETLEDS );
  keyboard_write( i );

  return 0;
}

/* Configure wich key events the keyboard will send for a given key */
/* If param == 1 then disable that message */
/* Params: Key code, Break, Typematic repeat */
static int keyboard_disablekeyevents( lua_State *L )
{
  #define makeOnly 0xFD
  #define makeBreak 0xFC
  #define makeType 0xFB
  int bk, tp, i;
  char ret;
  const char * buf;
  size_t len;

  /* Get params */
  luaL_checktype( L, 1, LUA_TSTRING );
  buf = lua_tolstring( L, 1, &len );
  bk  = luaL_checkinteger( L, 2 );
  tp  = luaL_checkinteger( L, 3 );

  /* Send operation code */
  if ( bk && tp ) 
  {
    printf( "make only\n" );
    keyboard_write( makeOnly );
  }

  if ( bk && ( tp == 0 ) )
  {
    printf( "make type" );
    keyboard_write( makeType );
  }

  if ( tp && ( bk == 0 ) )
  {
    printf( "make break" );
    keyboard_write( makeBreak );
  }

  /* Wait for ACK */
  ret = keyboard_getchar();

  if ( ret != ACK )
  {
    printf( "Error: No ACK ! " );
    return 0;
  }

  /* send key ( make ) code */
  for ( i=0; i<len; i++ )
  {
    /* Send key code */
    keyboard_write( buf[i] );

    /* Wait for ACK */
    ret = keyboard_getchar();

    if ( ret != ACK )
    {
      printf( "Error: No ACK ! " );
      return 0;
    }
  }

  /* Send echo ( ends key list ) */
  keyboard_write( ECHO );
}

/* Configure wich key events the keyboard will send for all keys */
/* If param == 1 then enable that message */
/* Params: Key code, Break, Typematic repeat */
static int keyboard_configkeys( lua_State *L )
{
  #define amakeOnly 0xF9
  #define amakeBreak 0xF8
  #define amakeType 0xF7
  #define amakeBreakType 0xFA
  int bk, tp;
  char ret;

  /* Get params */
  bk  = luaL_checkinteger( L, 1 );
  tp  = luaL_checkinteger( L, 2 );

  /* Enable all */
  printf( "make break" );
  keyboard_write( amakeBreakType );

  /* Wait for ACK */
  ret = keyboard_getchar();

  if ( ret != ACK )
  {
    printf( "Error: No ACK ! " );
    return 0;
  }

  /* Discable something ( or not ) */

  if ( ( bk == 0 ) && ( tp == 0 ) ) 
  {
    printf( "make only\n" );
    keyboard_write( amakeOnly );
  }

  if ( ( bk == 0 ) && ( tp == 1 ) )
  {
    printf( "make type" );
    keyboard_write( amakeType );
  }

  if ( ( tp == 0 ) && ( bk == 1 ) )
  {
    printf( "make break" );
    keyboard_write( amakeBreak );
  }

  /* Wait for ACK */
  ret = keyboard_getchar();

  if ( ret != ACK )
  {
    printf( "Error: No ACK ! " );
    return 0;
  }

  /* Send echo ( ends key list ) */
  keyboard_write( ECHO );

  /* Wait for Echo reply */
  keyboard_getchar();

  return 0;
}

const LUA_REG_TYPE keyboard_map[] = {
  { LSTRKEY( "clk" ), LFUNCVAL( keyboard_clk ) },
  { LSTRKEY( "init" ), LFUNCVAL( keyboard_init ) },
  { LSTRKEY( "receive" ), LFUNCVAL( keyboard_receive ) },
  { LSTRKEY( "setflags" ), LFUNCVAL( keyboard_setflags ) },
//  { LSTRKEY( "read" ), LFUNCVAL( keyboard_read ) },
  { LSTRKEY( "send" ), LFUNCVAL( keyboard_send ) },
  { LSTRKEY( "setleds" ), LFUNCVAL( keyboard_setleds ) },
  { LSTRKEY( "configkeys" ), LFUNCVAL( keyboard_configkeys ) },
  { LSTRKEY( "disablekeyevents" ), LFUNCVAL( keyboard_disablekeyevents ) },
  { LNILKEY, LNILVAL }
};

LUALIB_API int luaopen_keyboard ( lua_State *L )
{
  LREGISTER( L, "keyboard", keyboard_map );
};

