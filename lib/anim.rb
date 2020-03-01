require 'curses'

def draw(this, fps = 5)
  Curses.setpos(1, 1)
  Curses.addstr(this)
  Curses.refresh
  sleep(1.0 / fps)
end

loop do
  draw '(*_*)-|--|-'
  draw '(/*_*)-|--|-'
  draw '(/*_*/) -|--|-'
  draw '(/*_*)/  _|__|_'
  draw '(/*_*)/ ~ _|__|_'
  draw '(/*_*)/ ~   _|__|_'
  draw '(*_*)/       _|__|_'
  draw '\(*_*)/      _|__|_'
  draw '/(*_*)/      _|__|_'
  draw '\(*_*)/      _|__|_'
  draw '\(*_*)\      _|__|_'
  draw '  \(*_*)     _|__|_'
  draw '    (*_*)\   _|__|_'
  draw '     (*_*)   _|__|_'
  draw '       (*_*) _|__|_'
  draw '        (*_*)_|__|_'
  draw '             _|__|_(*_*)'
  draw '             _|__|_(*_*\)'
  draw '            -|--|-\(*_*\)'
  draw '        -|--|- ~ \(*_*\) '
  draw '      -|--|-    (*_*\)  '
  draw '     -|--|-   (*_*\)  '
  draw '     -|--|- (*_*\)  '
  draw '     -|--|-(*_*\) '
  draw '     -|--|-(*_*) '
  draw '(*_*)-|--|-     '
end
