" [IDEA] DSL to define 256color dynamic colorscheme "{{{
"
" Being able to define color/style based on other colors/hightlights
"
" +N is lighter (with a maximum per color)
" -N is darker (with a minium per color)
"
"   darker <-- -N  XYZ  +N --> lighter
"
" e.g:
"   Normal.bg-1
"   LineNr.fg+4
"   DiffAdd.style+bold
"   DiffDelete.bg
"
" This intents to work ONLY for the 256 color palette.
" I'll need a correspondance table between a given color and its color ramp.
"
"   :DynHi TargetHighlight style=st_expr,st_expr fg=col_expr bg=col_expr
"
" Virtual color, to give sementic meaning to some base color without having to
" map it to a syntax group.
"
"   :VirtCol _ErrorColor col=1
"   :VirtCol _Background col=234
"
"   :DynHi NeomakeErrorSign  fg=_ErrorColor  bg=Black.0
"
" Color ramps access by main color: (low value are darker)
" Use HSL color notation to find the proper ramp for each color.
" Nice playground: https://www.w3schools.com/colors/colors_hsl.asp
" H: Hue - which color is it
" S: Saturation - how much of it
" L: Light - 0%: black | 50%: optimal | 100%: white
"
" I want my color ramps to be a by Hue and ramping with a mix of S & L.
" With low ramp: less S and less L
" With high ramp: more S and more L
"
" Notable colors:
"   0 : the darkest
"   min : the darkest
"   bright : when the color is the brightest (/nicest)
"   (nice : when the color is the nicest to look at (always like bright?))
"   max : the lightest (before changing color, and not white)
"
" e.g:
"   Black.0  <-> 232
"   White.0  <-> 255 (cannot be brighter, can only go darker)
"   Red.0    <-> 52
"   Green.0  <-> 22
"
"   Blue.0      <-> 17
"   Blue.bright <-> 27 (?)
"
"   Orange.0      <-> 94 (or 58?)
"   Orange.bright <-> 202
"
"   Orange.0      <-> 94 (or 58?)
"   Orange.bright <-> 202
"
"
"
"   :VirtCol _ErrorColor  col=Red.nice
"   :VirtHi  _ErrorSign  fg=_ErrorColor  bg=Black.1
"   :DynHi NeomakeErrorSign   fg=_ErrorColor
"   :DynHi NeomakeErrorSign2  link=_ErrorSign
"
" In the future, could be a library/framework to create colorschemes, with
" functions to setup commands (DynHi, VirtHi, VirtCol)
" And a bunch of functions to manipulate the colors ramps, etc...
" (in VimScript/Lua, in Crystal, a CLI, .. will need a JSON for color ramps!)
"
"}}}
