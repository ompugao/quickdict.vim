syntax match quickdict_phrase /^\zs.\{-}\ze\s*\(\:\|{\)/
syntax match quickdict_example /\zs\%u25a0.\{-}\ze\(\%u25a0\|\%u25c6\|$\)/
syntax match quickdict_comment /\zs\%u25c6.\{-}\ze\(\%u25a0\|\%u25c6\|$\)/

"syntax match quickdict_meaning /: \zs.\{-}\ze\(\%u25a0\|\%u25a0\|$\)/
"\%u25a0 = ■ example
"\%u25c6 = ◆ comment

highlight link quickdict_phrase Statement "Keyword
highlight link quickdict_example Label
highlight link quickdict_comment Comment

let b:current_syntax = 'quickdict'
