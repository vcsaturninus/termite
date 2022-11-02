# termite

Terminal progress indicators and Lua bindings for basic terminal control sequences

Lua bindings for basic terminal control codes and sequences
------------------------------------------------------------

This module offers constants for some of the most common and widely implemented
`CSI` sequences. This includes commands to the terminal to adjust the position
of the cursor, and in particular some of the basic `SGR` sequences that allow
changing the color of terminal cells in various different ways or applying
certain effects.

The `SGR` constants are not to be used directly (e.g. fed to `print()`) but
instead they are expected to be passed as arguments to a `decorate()` function
made available by the module. The function takes the text to decorate as its first
parameter, and an arbitrary number (including 0) of **SGR** attributes to apply
to the text.

For example:
```Lua
local termite = require("termite")

-- print '.' with background and foreground colors inverted, and make it
-- 'blink' at a slow rate.
print(termite.decorate('.', termite.INVERT, termite.SLOWBLINK))
```

Similarly, constants that represent commands to the terminal to
_adjust the cursor position_ are meant to be be passed argument to
`termite.move()`, rather than directly to `print()`.

The only constants that should/must be passed directly to `print()` are
`C0` control codes (e.g. backspace, newline etc) and some mnemonic constants
defined in `termite` for clearing the screen or line in a few different ways.

For example here's a quick implementation of the `clear` command:
```Lua
io.write(termite.CLEARS .. termite.move(termite.CUP))
```

Terminal progress indicators
------------------------------





