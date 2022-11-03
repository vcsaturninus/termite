# termite

Terminal progress indicators and Lua bindings for basic terminal control sequences

Lua bindings for basic terminal control codes and sequences
------------------------------------------------------------

This module defines various constants for some of the most common and widely
implemented terminal control sequences as well as several convenience functions
and mnemonics to increase usability.

This includes:
 * basic `C0` control codes: these represent 1-byte codes most users are familiar
   with as 'backslash escapes' e.g. '\n' for newline, '\t' for tab etc.
 * Some mnemonic CSI sequence wrappers for clearing (part of) the screen or current line
 * CSI sequences for manipulating cursor position
 * SGR sequences for decorating terminal cells with color and other effects.

These are expected to be used as follows:
 * the `C0` control codes and the mnemonic CSI sequence wrappers for screen
   or line-clearing should (and must) be embedded directly in strings. e.g.
```Lua
print(termite.HT .. "1. First item")
```
   will precede the specified string with a `\t`. Of course, in many cases the
   user may as well simply embed `\t` directly instead as most facilities for
   writing to the standard streams recognize basic backslash escapes.

 * The `SGR` constants are not to be used directly (e.g. fed to `print()`) but
   instead they are expected to be passed as arguments to a `decorate()` function
   made available by the module. The function takes the text to decorate as its first
   parameter, and an arbitrary number (including 0) of **SGR** attributes to apply
   to the text. It's the _result_ of this function that should/can be printed out or
   embedded in a string. For example:
```Lua
-- print '.' with background and foreground colors inverted, and make it
-- 'blink' at a slow rate.
print(termite.decorate('.', termite.INVERT, termite.SLOWBLINK))
```

 * Similarly, other CSI sequences (with the exceptions above) are meant to be be
   passed as arguments to `termite.move()`. It's the result of this function
   that should/can be printed out or embedded in a string. For instance:
```Lua
-- simple implementation of the 'clear' command
io.write(termite.CLEARS .. termite.move(termite.CUP))
```

**For the list of constants as well as documentation on the aforementioned
functions, see `termite.lua`**.


Terminal progress indicators
------------------------------

The second goal of `termite` is to make available a set of basic progress
indicators to be used by scripts running in the terminal that could use this
sort of feature (particularly scripts that perhaps end up blocking/hanging while
waiting on some slower IO OS facility e.g. sockets or writing to disk).

Each different type of such indicator is created via its own separate function.
The functions are meant to be highly and easily customizable: the user can
easily change the filler character, the 'void' character, the width of the bar
(in the case of progress bars), the color, accompanying messages etc.

To achieve this many of the functions take a host of parameters; on the other
hand, most of the parameters are optional. Some sane defaults are provided if
no customization is done by the user.

All progress indicators provide the same interface:
 * create a specific progress indicator object by calling the corresponding
   function in `termite`. This should be done before the associated loop is
   entered.
 * call the object's `:next()` method for advancing its internal state by one
   unit. This _should_ be done on each loop pass.
 * call the object's `:report()` method for printing out its representation of
   the current progress. This is specific to each progress indicator and the
   user can specify a custom accompanying message to be printed. This _should_
   be done on each loop pas.
 * call the object's `:done()` method after the loop for one last report print.
   The user can specify a custom accompanying message to be printed as well as a number of
   seconds to wait before clearing the line (so the user has time to see).

Since the `:next()` and `:report()` methods are expected to be called with each
iteration around the loop, the following crucial point must be noted:
 * some of the progress indicators are meant for **definite** iteration: the
   user _must_ know beforehand _and_ specify the number of iterations (steps)
   the loop will have. This category includes percentage loaders and progress
   bars.
 * some of the progress indicators are meant for **indefinite** iteration: in this case
   the user does _not_ know the number of passes around the loop upfront. The
   progress indicator will therefore display not an actual progress indicator
   (as the name would imply) but a 'busy' anmation to indicate that work is
   being done. This category includes spinners, 'cyclc laders' and 'ourobourous'
   bars (yes, I've just made these up).

For specific comments on each of the above, see `termite.lua`.

### Examples

#### Percentage Loaders

```Lua
local termite = require("termite.lua")

local n = 11
local loader = termite.get_percentage_loader(n)
for i=1,n do
    loader:report("Loading ...")
    loader:next()
    os.execute("sleep 0.2")
end
loader:done("Done ...", 2)
```
![Default percentage Loader](files/default_percentage_loader.gif)

```Lua
local termite = require("termite.lua")

local n = 11
local loader = termite.get_percentage_loader(n, termite.INVERT)
for i=1,n do
    loader:report("Loading ...")
    loader:next()
    os.execute("sleep 0.2")
end
loader:done("Done ...", 2)
```
![Customized percentage Loader](files/inverted_percentage_loader.gif)


