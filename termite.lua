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

-----------------------
-- C0 control codes
----------------------
-- These are the most basic single-byte control chars: \n for newline,
-- \b for backspace etc.
--
-- A C0 control code can be expressed as a standalone embedded 1-byte char
-- or in a sequence initiated by the SCI (making it therefore a CSI sequence),
-- followed by a character identifying the control code. For instance,
-- tab (\t) can be expressed either as \x09 or as \x1B[I
--
M.BEL   = '\x07'   -- bell
M.BS    = '\x08'   -- backspace
M.HT    = '\x09'   -- horizontal tab
M.LF    = '\x0A'   -- line feed
M.FF    = '\x0C'   -- form feed
M.CR    = '\x0D'   -- carriage return
M.ESC   = '\x1B'   -- escape; starts all sequences (C0, CSI etc)

------------------
-- CSI sequences
------------------
--
-- The combination of the ESC code followed by the opening square bracket '['
-- is referred to as the CSI - Control Sequence Introducer;
-- The CSI functions as an escape, preceding most useful control sequences --
-- which are consequently referred to as CSI sequences.
M.CSI  = M.ESC .. '['

-- Mnemonics for clearing (parts of) screen or line
M.CLEARS        = M.CSI .. "2J"    -- clear whole screen
M.CLEARS_TO     = M.CSI .. "1J"    -- clear everything on screen before cursor
M.CLEARS_FROM   = M.CSI .. "0J"    -- clear everything on screen after cursor

M.CLEARL        = M.CSI .. "2K"    -- clear whole line
M.CLEARL_TO     = M.CSI .. "1K"    -- clear everything on the line before cursor
M.CLEARL_FROM   = M.CSI .. "0K"    -- clear everything on the line after cursor

-- Control sequences for manipulating cursor position
M.CUU   = 'A'    -- move cursor one cell up (cursor up)
M.CUD   = 'B'    -- //-- down (cursor down)
M.CUF   = 'C'    -- //-- to the right (cursor forward)
M.CUB   = 'D'    -- //-- to the left (cursor back)
M.CNL   = 'E'    -- move cursor n (default 1) lines down, to the start of the line
M.CPL   = 'F'    -- move cursor n (default 1) lines up, to the start of the line
M.SU    = 'S'    -- scroll whole page up by n (default 1) lines
M.SD    = 'T'    -- scroll whole page down by n (default 1) lines
M.CUP   = 'H'    -- move cursor to row n, column m (default 1,1).

------------------
-- SGR sequences
------------------
-- The most commonly used attributes are the so-called Select Graphic Rendition (SGR) subset
-- of CSI sequences.
-- These are used to set display attributes (color, style etc). The list provided below
-- is not exhaustive: it includes only the basic, most widely supported attributes.
--
-- SGR SCI sequences are of the form: CSI n m (where n is a numeric value).
--
-- An arbitrary number of SGR attributes can be set as part of the same sequence,
-- separated by semicolons: <CSI>30;31;35m
--
-- resets any terminal properties effected by previously applied SGR sequences.
M.SGR_RESET   = M.CSI .. "0" .. "m"

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
---------------------------------------------------------------
---------------------------------------------------------------

--[[
    Return a CSI control sequence for conveying the specified movement action.

--> dir, constant
    One of the constants listed above representing a possible cursor movement.

--> n, int
    @optional
    @default 1
    The number of cells to move in the specified direction.

--> m, int
    @optional
    @default 1
    If dir is M.CUP (cursor position), then a second parameter -m- can be specified;
    n and m are interpreted as the row and column, respectively, to move the cursor
    to. If unspecified, these default to 1,1 (top left corner).
--]]
function M.move(dir, n, m)
    assert(dir, "Mandatory parameter left unspecified: 'dir'")
    if dir ~= M.CUP then
        return M.CSI .. tostring(n or 1) .. dir
    else
        return M.CSI .. tostring(n or 1) .. ';' .. tostring(m or 1) .. dir
    end
end

--[[
    Return a CSI SGR sequence of semicolon-separated attributes.

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

---------------------------------------------------------------------------------

-----------------------------------------
----- Graphic Progress Indicators -------
----------------------------------------

-- Public interface of all Loader objects.
--
-- Each specific loader type is created via a call to one of the
-- functions below: get_cyclic_loader(), get_loading_spinner() etc.
-- These functions first create an instance of Loader, then populate
-- it with specific fields which vary from case to case.
--
-- The interface implemented by Loader consists of 3 methods the client
-- can and must call for any loader type:
--   * .next()   -- advance progress state by one unit
--   * .report() -- print out a progress report accompanied by optional message
--   * .done()   -- print final progress state accompanied by optional message
--
-- Each loader will implement these function differently. To hook into the generic
-- interface exposed by Loader, every specific loader object must implement 2 methods:
--   * .advance__()  -- called by .next()
--   * .report__()   -- called by .report()
--
-- This allows a primitive form of interface inheritance and virtual method overriding.
--
local Loader = {}
Loader.__index = Loader

function Loader.next(self)
    -- hook for overriding
    self:advance__()
end

function Loader.report(self, msg)
    self:report__(msg)
    io.write(M.move(M.CPL, 1) .. M.CLEARL)  -- clear previous line
end

-- Clear line: this must be done to prevent the case where a wide progress bar
-- or somesuch indicator is used and subsequent text only partially overwrites it.
-- Wait specified number of seconds before clearing so the user has
-- time to see whatever final report (and optional message) is printed.
function Loader.done(self, msg, waitsecs)
    self:report__(msg)

    if waitsecs then
        os.execute("sleep " .. tostring(waitsecs))
    end
    io.write(M.move(M.CPL, 1) .. M.CLEARL)  -- clear previous line
end

-- Create Loader stub with public interface implementation
function Loader.new()
    return setmetatable({}, Loader)
end

--[[
    Create and return a percentage loader.

--> num_steps
    The total number of steps until completion. This must be known
    beforehard and so this loader is only appropriate for DEFINITE
    iteration.

<-- return, table
    A loader instance.
--]]
function M.get_percentage_loader(num_steps, ...)
    local self           = Loader.new()
    self.whole           = num_steps -- total number of steps until 100%
    self.steps_completed = 0         -- number of steps completed so far
    self.progress        = math.floor(self.steps_completed / self.whole)
    self.sgr_attr        = {...}  -- any number of SGR attributes specified

    -- format before printing
    function self.format__(char, ...)
        return M.decorate(char, ...)
    end
    -- increment step and adjust loader state
    function self.advance__(self)
        if self.steps_completed == self.whole then
            return -- complete
        end
        self.steps_completed = self.steps_completed+1
        self.progress        = math.floor((self.steps_completed / self.whole) * 100)
    end

    -- print a report of current progress to stdout
    function self.report__(self, msg)
        print(string.format("%s %s", self.format__(self.progress .. '%', table.unpack(self.sgr_attr)), msg or ""))
    end

    return self
end

--[[
    Create and return a spinning loader.

    This loader is appropriate for INDEFINITE iteration
    where the number of steps is unknown starting out.

--> positions, array
    @optional
    @default {"|", "/", "-", "\\"}
    An array of char symbols that this function will cycle through with
    every completed step.

--> ..., array
    @optional
    @default termite.BOLD
    An array of SGR attributes to apply to the symbol when it gets printed to
    the console. This means that if POSITIONS is specified, each element in that
    array will have the same attributes applied.

    Note that if the user specifies a POSITIONS array they could even customize
    each element independently BEFORE inserting it into the array; that would be
    a more granular way of customizing each step symbol. Whereas the variadic
    argument is a list of SGR attributes to be applied indiscriminately to ALL.

<-- return, table
    A loader instance.
--]]
function M.get_loading_spinner(positions, ...)
    if positions then
        assert(type(positions) == "table", "Invalid param; 'positions' must be a table")
    end

    local self           = Loader.new()
    self.positions       = positions or {"|", "/", "-", "\\"}
    self.num_positions   = #self.positions
    self.steps_completed = 1      -- index of the current position
    self.sgr_attr        = {...}  -- any number of SGR attributes specified

    -- format before printing
    function self.format__(char, ...)
        return M.decorate(char, M.BOLD, ...)
    end

    function self.advance__(self)
        self.steps_completed = (self.steps_completed % self.num_positions) + 1
    end

    function self.report__(self, message)
        print(string.format("%s %s",
                            self.format__(self.positions[self.steps_completed], table.unpack(self.sgr_attr)),
                            message or "")
             )
    end

    return self
end

--[[
    Create and return a progress bar.

    A progress bar is made up of two markers either side, a filler symbol
    in between representing progress made, and a 'void' symbol (typically
    whitespace) indicating how much progress is left to be made.

    Each unit has a corresponding progress weight depending on the total number
    of units. For example, in a 15-unit progress bar, each unit is
    worth 1/15.

--> steps, int
    The total number of steps until completion. This must be known
    beforehard and so this loader is only appropriate for DEFINITE
    iteration.

--> units, int
    @optional
    @default 30
    How many units the progress bar consists of. Since the width of the bar
    is directly proportional to the number of units, this should be something
    reasonable that fits on the screen.

--> lmarker, char
    @optional
    @default '['
    The left marker to use to bound the progress bar on the left side.

--> rmarker, char
    @optional
    @default '['
    The right marker to use to bound the progress bar on the right side.

--> filler, char
    @optional
    @default '#'
    The unit symbol to use between the two progress bar markers in order
    to represent progress.

--> void, char
    @optional
    @default ' '
    The unit to use to show how much more progress is left to be made.

<-- return
    A loader instance.
--]]
function M.get_progress_bar(num_steps, num_units, lmarker, rmarker, filler, void)
    local self = Loader.new()
    self.whole            = num_units or 30  -- total number of units representing a completed whole
    self.units_completed  = 0                -- total number of units completed
    self.total_steps      = num_steps        -- total number of steps representing a completed whole
    self.steps_completed  = 0                -- total number of steps completed
    self.lmarker = lmarker or '['
    self.rmarker = rmarker or ']'
    self.filler  = filler or '#'  -- symbol used to fill the bar to represent progress
    self.void    = void or ' '    -- symbol used to show how much of the bar is left to fill

    function self.advance__(self)
        -- if complete, pregres bar is filled
        if self.steps_completed == self.total_steps then return end

        -- increment number of steps completed
        self.steps_completed = self.steps_completed + 1

        -- the number of units is incremented IFF the ratio of
        -- steps completed : total steps is >= to the ratio of
        -- units completed : whole.
        if self.steps_completed / self.total_steps >= (self.units_completed / self.whole) then
            local progress_made = self.steps_completed / self.total_steps
            self.units_completed = math.floor(progress_made * self.whole)
        end
    end

    function self.report__(self, msg)
        print(string.format("  %s%s%s%s %s",
                                self.lmarker,
                                string.rep(self.filler, self.units_completed),
                                string.rep(self.void, self.whole - self.units_completed),
                                self.rmarker,
                                msg or "")
                                )
    end

    return self
end

--[[
    Create and return a repeating 'ourobourous' progress bar.

    Like a normal progress bar (see that FMI), but appropriate for indefinite
    iteration: number of steps is unknown starting out; the progress bar oscillates
    for as long as the iteration continues.
--]]
function M.get_ouroborous_bar(num_units, lmarker, rmarker, filler, void)
    local self = Loader.new()

    self.whole            = num_units or 30  -- total number of units representing a completed whole
    self.units_completed  = 0                -- total number of units completed
    self.lmarker = lmarker or '['
    self.rmarker = rmarker or ']'
    self.filler  = filler or '#'   -- symbol used to fill the bar to represent progress
    self.void    = void or ' '      -- symbol used to show how much of the bar is left to fill

    function self.advance__(self)
        -- if complete, progress bar is filled; flip void and filler unit symbols
        if self.units_completed == self.whole then
            self.void, self.filler = self.filler, self.void
            self.units_completed   = 0
        end

        -- increment number of steps completed
        self.units_completed = self.units_completed+1
    end

    function self.report__(self, msg)
        print(string.format("  %s%s%s%s %s",
                                self.lmarker,
                                string.rep(self.filler, self.units_completed),
                                string.rep(self.void, self.whole - self.units_completed),
                                self.rmarker,
                                msg or "")
                                )
    end

    return self
end

--[[
    Create and return a cyclic symbol loader.

    This loader offers a different take on progress bars suitable
    for indefinite iteration. It's much like the ouroborous bar,
    but instead of a progress bar alternating between being filled
    and emptied, this loader moves a filler symbol left to right through
    every cell along the width of the bar. A SET of symbols can be
    specified rather than a single symbol, in which case the loader
    will cycle through the set as it goes from left to right.

--> symbols, array
    @optional
    @default {'#'}
    Array of symbols to cycle through.

FMI, see the comments for the Ourobourous loader function.
For '...' meaning, see comment for loading_spinner.
--]]
function M.get_cyclic_loader(units, lmarker, rmarker, symbols, void, ...)
    if symbols and (type(symbols) ~= "table" or #symbols == 0) then
        error("Invalid parameter 'symbols': must be an array with at least one element")
    end

    local self = Loader.new()
    self.whole            = num_units or 30   -- total number of units representing a completed whole
    self.units_completed  = 0                 -- total number of units completed
    self.lmarker  = lmarker or '['
    self.rmarker  = rmarker or ']'
    self.symbols  = symbols or {'#'}   -- symbol used to fill the bar to represent progress
    self.void     = void or ' '        -- symbol used to show how much of the bar is left to fill
    self.sgr_attr = {...}              -- any number of SGR attributes specified
    self.current = self.symbols[1]

    -- format before printing
    function self.format__(char, ...)
        return M.decorate(char, M.BOLD, ...)
    end

    function self.report__(self, msg)
        print(string.format("  %s%s%s%s%s %s",
                            self.lmarker,
                            string.rep(self.void, self.units_completed-1),
                            string.rep(self.format__(self.current, table.unpack(self.sgr_attr)), 1),
                            string.rep(self.void, self.whole - self.units_completed),
                            self.rmarker,
                            msg or "")
                            )
    end

    function self.advance__(self)
        if self.units_completed == self.whole then
            self.units_completed=0
        end

        -- increment number of steps completed
        self.units_completed = self.units_completed+1
        local idx    = (self.units_completed % #self.symbols) + 1
        self.current = self.symbols[idx]
    end

    return self
end

return M
