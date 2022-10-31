--[[
----------------------------------------------------------------
-- termite 
--      Lua bindings for basic terminal control sequences --
--      (c) 2022 vcsaturninus -- vcsaturninus@protonmail.com
----------------------------------------------------------------

-- -- -- Contents: -- -- --
 * .say()       -- format message and print to stream or stdout
--]]


local M = {}



--[[--------------------------------
    ANSI terminal escape sequences.
--]]-------------------------------

-- \0x1b[ (\27 decimal) is referred to as the CSI - Control Sequence Introducer; 
-- The CSI functions as an escape, preceding most useful control sequences -- 
-- which are consequently referred to as CSI sequences.
M.CSI  = "\27["

-- resets any terminal properties effected by previously applied SGR sequences.
M.SGR_RESET   = M.CSI .. "0" .. "m"

-- The most commonly used attributes are the so-called Select Graphic Rendition (SGR) subset
-- of CSI. These are used to set display attributes (color, style etc). The list provided below 
-- is not exhaustive: it includes only the basic, most widely supported attributes.
--
-- SGR SCI sequences are of the form: CSI n m (where n is a numeric value).
--
-- An arbitrary number of SGR attributes can be set as part of the same sequence, 
-- separated by semicolons: <CSI>30;31;35m
--
M.BOLD        = 1       -- make text bold  (increased intensity)
M.FAINT       = 2       -- make text faint (decreased intensity)
M.UNDERLINE   = 4       -- s.e.
M.SLOWBLINK   = 5       -- sets blinking attribute (< 150/minute)
M.INVERT      = 7       -- swap background and foreground colors
M.STRIKE      = 9       -- strike the text through
M.NORMINTENS  = 22      -- not bold and not faint: normal intensity
M.NOUNDERLINE = 24      -- remove underlining attribute
M.NOBLINK     = 25      -- turn off blinking attribute
M.NOINVERT    = 27      -- turn off INVERT attribute

---------------------------------------------------------------------------
-- This Module only lists the basic 4-bit colors; 
-- That is, 2^4 foreground and 2^4 backround colors, respectively.
-- Modern terminal emulators now vastly support 'true color', where
-- 8 bits (2^8 colors for foreground, backround) are used for encoding 
-- the color set. However, for basic purposes these are rarely a necessity.
---------------------------------------------------------------------------
-- foreground colors
M.FG_BLACK           = 30
M.FG_RED             = 31
M.FG_GREEN           = 32
M.FG_YELLOW          = 33
M.FG_BLUE            = 34
M.FG_MAGENTA         = 35
M.FG_CYAN            = 36
M.FG_WHITE           = 37
M.FG_BRIGH_BLACK     = 90   -- gray
M.FG_BRIGHT_RED      = 91
M.FG_BRIGHT_GREEN    = 92
M.FG_BRIGHT_YELLOW   = 93
M.FG_BRIGHT_BLUE     = 94
M.FG_BRIGHT_MAGENTA  = 95
M.FG_BRIGHT_CYAN     = 96
M.FG_BRIGHT_WHITE    = 97

-- background colors
M.BG_BLACK           =  M.FG_BLACK               + 10
M.BG_RED             =  M.FG_RED                 + 10
M.BG_GREEN           =  M.FG_GREEN               + 10
M.BG_YELLOW          =  M.FG_YELLOW              + 10
M.BG_BLUE            =  M.FG_BLUE                + 10
M.BG_MAGENTA         =  M.FG_MAGENTA             + 10
M.BG_CYAN            =  M.FG_CYAN                + 10
M.BG_WHITE           =  M.FG_WHITE               + 10
M.BG_BRIGH_TBLACK    =  M.FG_BRIGH_BLACK         + 10
M.BG_BRIGHT_RED      =  M.FG_BRIGHT_RED          + 10
M.BG_BRIGHT_GREEN    =  M.FG_BRIGHT_GREEN        + 10
M.BG_BRIGHT_YELLOW   =  M.FG_BRIGHT_YELLOW       + 10
M.BG_BRIGHT_BLUE     =  M.FG_BRIGHT_BLUE         + 10
M.BG_BRIGHT_MAGENTA  =  M.FG_BRIGHT_MAGENTA      + 10
M.BG_BRIGHT_CYAN     =  M.FG_BRIGHT_CYAN         + 10
M.BG_BRIGHT_WHITE    =  M.FG_BRIGHT_WHITE        + 10

--------------------------------------------------------
-- Control sequences for manipulating cursor position
--------------------------------------------------------
M.CLEARS        = M.CSI .. "2J"    -- clear whole screen
M.CLEARS_TO     = M.CSI .. "1J"    -- clear everything on screen before cursor
M.CLEARS_FROM   = M.CSI .. "0J"    -- clear everything on screen after cursor

M.CLEARL        = M.CSI .. "2K"    -- clear whole line
M.CLEARL_TO     = M.CSI .. "1K"    -- clear everything on the line before cursor
M.CLEARL_FROM   = M.CSI .. "0K"    -- clear everything on the line after cursor

M.UP            = 'A'    -- move cursor one cell up
M.DOWN          = 'B'    -- //-- down
M.RIGHT         = 'C'    -- //-- to the right
M.LEFT          = 'D'    -- //-- to the left
M.NEXTL         = 'E'    -- move cursor n (default 1) lines down, to the start of the line
M.PREVL         = 'F'    -- move cursor n (default 1) lines up, to the start of the line

-- todo add CS0

--[[
    Return a CSI control sequence for conveying the specified movement action.

--> dir, constant
    One of the constants listed above representing a possible cursor movement.

--> n, int
    @optional
    @default 1
    The number of cells to move in the specified direction.
--]]
function M.move(dir, n)
    assert(dir, "Mandatory parameter left unspecified: 'dir'")
    return M.CSI .. tostring(n or 1) .. dir
end

--[[
    Return a CSI sequence of semicolon-separated attributes.

--> ...
    An arbitrary number of SGR attributes to format into a single CSI sequence.
    Each attribute must be one of the SGR constants defined in this module.
    At least one attribute must be specified.
--]]
local function format_sgr_sequence(...)
    local sequence = ""
    local sep      = ";"
    local sgr_attributes = {...}

    assert(#sgr_attributes > 0, "List of SGR attributes must be non-empty")

    for _,attr in ipairs(sgr_attributes) do
        sequence = sequence .. tostring(attr) .. sep
    end
    
    -- strip trailing ';' and add CSI prefix and SGR suffix
    return string.format("%s%s%s", M.CSI, sequence:sub(1,-2), "m")
end

--[[
    Decorate text according to arbitrary number of SGR attributes specified.

    If no attribute is specified, text is returned unchanged.
    Otherwise the attributes are formatted and applied to the text which
    is then returned.

--> text, string
    A string to be decorated with terminal SGR attributes.

--> ..., list
   @optional
   A list of SGR attributes defined in this module.

<-- return
    A string representing the input text decoarated with specified attributes.
--]]
function M.decorate(text, ...)
    assert(text, "Mandatory param left unspecified: 'text'") 

    if #{...} == 0 then return text end
    
    return format_sgr_sequence(...) .. text .. M.SGR_RESET
end

return M
