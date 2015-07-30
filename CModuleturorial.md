Obs: This is a preliminary text for a tutorial that is now being maintained on the eLua User Labs wiki.eluaproject.net at http://wiki.eluaproject.net/Tutorials/cmodules



# Writing a generic/platform-independent eLua C module #
by Marcelo Politzer

This is a step by step tutorial on how to make an eLua C module and put it on a romtable. It will not teach how to do a normal Lua bind, because there are lots of good tutorials about this on the internet.

1:
So, as an example, lets say you want to write a C driver for a device and add it to your eLua image, together with a Lua bind, so it can be used by a Lua program.
This will be a platform independent driver called imag.c that won't do
anything cool, just return a number. It will be placed at 'src/modules' with
the other generic (platform independent) drivers and it will go like this:

```
/*>> Begin of file*/

/* Not sure if all they are all necessary, but it works like this. */
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#include "common.h"
#include "auxmods.h"
#include "lrotable.h"
#include "platform_conf.h"
#define MIN_OPT_LEVEL 2
#include "lrodefs.h"

/* Our example idiotic function */
static int imag_dostuff( lua_State *L ){
	lua_pushinteger( L, 43 );
	return 1;
}

/* Our magic constant */
#define IMAG_MAGICNUMBER 43

/* Here is the definition of the Romtable. Note the macros that we don't have
 * in normal Lua. They are features introduced in eLua to make possible the
 * registration not only of functions but constants as well. These macros are
 * important, remember that we're not using a luaL_Reg as in normal Lua.
 * So remember to use them.
 * For more about this go to 'src/lua/lrodefs.h' & 'src/lua/lrotable.h'.
 */
const LUA_REG_TYPE imagi_map[] = {
	{ LSTRKEY( "dostuff" ), LFUNCVAL( imag_dostuff ) },
	{ LSTRKEY( "magic_number" ), LINTKEY( IMAG_MAGICNUMBER ) },
	{ LNILKEY, LNILVAL }
};

/* Now we have another tricky part, here you have 2 possible registrations of
 * your module. The first case, the '#if LUA_OPTIMIZE_MEMORY > 0', we get 
 * all of this on the romtable, so... Nothing to register.
 * The '#else' part we register it like in Lua and the function and constant will live in RAM.
 */
LUALIB_API int luaopen_imag( lua_State *L ){
#if LUA_OPTIMIZE_MEMORY > 0
	return 0;
#else
	LREGISTER( L, AUXLIB_IMAG, imag_map );
	return 1;
#endif
}

/* >> End of file */
```

Congratulations, you've finished your eLua module! BUT! There are some more
steps to do to make it work. =(.

2:
The next step is to add your module to the list of modules to be build, for
this we'll edit the 'SConstruct' file.

Search for the line with 'module\_names' in it and add you file to it.
like: modules\_names = " ... imag.c"

3:
Now we'll put an entry of our module at 'src/modules/auxmods.h', like the
ones already there. In this case:
#define AUXLIB\_IMAG "imag"
LUALIB\_API int ( luaopen\_imag )( lua\_State **L );**

4:
By the time this tutorial was written, there wasn't any place to say that our
module wants to go to rom in a platform independent way. Because of this,
I've placed it definition under a specific platform. It is possible to put
the same definition for all the platforms, but hopefully it will be changed
by the time you read this. So...

As an example I'll put it under lpc17xx. So edit the
'src/platform/lpc17xx/platform\_conf.h' and add:

_ROM( AUXLIB\_IMAG, luaopen\_imag, imag\_map )_

to #define LUA\_PLATFORM\_LIBS\_ROM

like this:

```
/* Code part */

#define LUA_PLATFORM_LIBS_ROM\
  _ROM( AUXLIB_PIO, luaopen_pio, pio_map )\
  _ROM( AUXLIB_UART, luaopen_uart, uart_map )\
  _ROM( AUXLIB_PD, luaopen_pd, pd_map )\
  _ROM( AUXLIB_TMR, luaopen_tmr, tmr_map )\
  _ROM( AUXLIB_TERM, luaopen_term, term_map )\
  _ROM( AUXLIB_PACK, luaopen_pack, pack_map )\
  _ROM( AUXLIB_BIT, luaopen_bit, bit_map )\
  _ROM( AUXLIB_CPU, luaopen_cpu, cpu_map )\
  _ROM( AUXLIB_PWM, luaopen_pwm, pwm_map )\
  _ROM( LUA_MATHLIBNAME, luaopen_math, math_map )\
  _ROM( AUXLIB_ELUA, luaopen_elua, elua_map )\
  _ROM( PS_LIB_TABLE_NAME, luaopen_platform, platform_map ) \
  _ROM( AUXLIB_IMAG, luaopen_imag, imag_map )

/* End of Code */
```

Now your module will be built with eLua! Good luck. =)

The main eLua site has some more information on this at:
http://www.eluaproject.net/en_building.html
http://www.eluaproject.net/en_arch_ltr.html

If you still have problems or questions, pls feel free to send an email to the eLua list. You can register at https://lists.berlios.de/mailman/listinfo/elua-dev

Enjoy eLua !!!

Best,
Marcelo