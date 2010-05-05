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

typedef struct sPin
{
  pio_type pin, port;
} tPin;

// Pin Configuration
tPin P_CLK, P_DATA, P_CLK_PD, P_DATA_PD;

// Start, Stop and Parity bits ignore configuration
char igStart = USE;
char igStop = USE;
char igParity = USE;

static tPin convertPin( int p )
{
  tPin result;
  result.port = PLATFORM_IO_GET_PORT( p );
  result.pin = ( 1 << PLATFORM_IO_GET_PIN( p ) );

  return result;
}

static void setPinVal( tPin p, char val )
{
  if ( val )
    platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_SET );
  else
    platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_CLEAR );
}

static void setPinDir( tPin p, char dir )
{
  if ( dir == DIR_IN )
    platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_DIR_INPUT );
  else
    platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_DIR_OUTPUT );
}

static int getPinVal( tPin p )
{
  return platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_GET );
}

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

static int keyboard_receive( lua_State *L )
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

  /* lua_pushinteger( L, data ); */

  /* Check start bit */
  if ( ( ( data & 1 ) == 1 ) && ( igStart == USE ) )
  {
    lua_pushinteger( L, ERROR );
    return 1;
  }

  /* Check stop bit ( com problema )*/
  if ( ( ( data & 1024 ) == 0 ) && ( igStop == USE ) )
  {
    // lua_pushinteger( L, ERROR );
    lua_pushinteger( L, 1 );
    return 1;
  }

  /* Check CRC bit */
  if ( ( checkCRC( data ) == 0 ) && ( igParity == USE ) )
  {
    // lua_pushinteger( L, ERROR );
    lua_pushinteger( L, 3 );
    return 1;
  }

  data = data >> 1;
  data = data & 255;
  lua_pushinteger( L, data );

  return 1;
}

static int keyboard_read( lua_State *L )
{
  int qtd = luaL_checkinteger( L, 1 );
  int i = 0;
  int c;

  lua_pop( L, 1 );

  while ( i < qtd )
  {
    keyboard_receive( L );

    c = luaL_checkinteger( L, 1 );
    lua_pop( L, 1 );

    if ( c == 28 )
      printf( "a" );
    else
      if ( c == 50 )
         printf( "b" );
      else
        continue;

    i ++;
  }

  return 0;
}
const LUA_REG_TYPE keyboard_map[] = {
  { LSTRKEY( "clk" ), LFUNCVAL( keyboard_clk ) },
  { LSTRKEY( "init" ), LFUNCVAL( keyboard_init ) },
  { LSTRKEY( "receive" ), LFUNCVAL( keyboard_receive ) },
  { LSTRKEY( "setflags" ), LFUNCVAL( keyboard_setflags ) },
  { LSTRKEY( "read" ), LFUNCVAL( keyboard_read ) },
  { LNILKEY, LNILVAL }
};

LUALIB_API int luaopen_keyboard ( lua_State *L )
{
  LREGISTER( L, "keyboard", keyboard_map );
};

