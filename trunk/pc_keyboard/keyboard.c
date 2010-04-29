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

#define dirOut 0
#define dirIn 1

typedef struct sPin
{
  pio_type pin, port;
} tPin;

// Pin Configuration
tPin P_CLK, P_DATA, P_CLK_PD, P_DATA_PD;

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
  if ( dir == dirIn )
    platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_DIR_INPUT );
  else
    platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_DIR_OUTPUT );
}

static int getPinVal( tPin p )
{
  return platform_pio_op( p.port, p.pin, PLATFORM_IO_PIN_GET );
}

static int keyboard_init( lua_State *L )
{
  P_CLK = convertPin( luaL_checkinteger( L, 1 ) );
  P_DATA = convertPin( luaL_checkinteger( L, 2 ) );
  P_CLK_PD = convertPin( luaL_checkinteger( L, 3 ) );
  P_DATA_PD = convertPin( luaL_checkinteger( L, 4 ) );
  setPinDir( P_CLK_PD, dirOut );
  setPinDir( P_DATA_PD, dirOut );
  setPinDir( P_DATA, dirIn );
  setPinDir( P_CLK, dirIn );

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

  data = data >> 1;
  data = data & 255;
  lua_pushinteger( L, data );

  return 1;
}


/*
static int keyboard_receive( lua_State *L )
{
  int p;
  tPin pin;

  p = luaL_checkinteger( L, 1 );
  pin = convertPin( p );

  lua_pushinteger( L, getPinVal( pin ) );

  return 1;
}
*/
const LUA_REG_TYPE keyboard_map[] = {
  { LSTRKEY( "clk" ), LFUNCVAL( keyboard_clk ) },
  { LSTRKEY( "init" ), LFUNCVAL( keyboard_init ) },
  { LSTRKEY( "receive" ), LFUNCVAL( keyboard_receive ) },
  { LNILKEY, LNILVAL }
};

LUALIB_API int luaopen_keyboard ( lua_State *L )
{
  LREGISTER( L, "keyboard", keyboard_map );
};

