Glide trace
===========

Glide2x call (re)tracing. Inspired by ApiTrace https://apitrace.github.io

The wrapper captures all glide calls to a file and then forwards the calls to the real wrapper.
Glide2x_retrace can replay the calls afterwards (even on different glide wrappers).
It can be used for debugging or performance tuning of wrappers, function call inspection or just plain fun, as a tool for replaying your favourite games.


Usage and compilation
-----------

Use recent Lazarus with Freepascal for Win32 (version 3.0 and higher) to compile.
Older versions may work, but are not recommended.
Each tool has a separate project file.

You will also need 
* a real glide wrapper 
  * dgVoodoo (debug version) - recommended, http://dege.freeweb.hu/dgVoodoo2/dgVoodoo2.html
  * nGlide (use alt+enter to switch to windowed mode), http://www.zeus-software.com/downloads/nglide
  * OpenGLide
  * or other
* SDL 1.2 for retrace, https://libsdl.org - put the dll next to glide2x_retrace or to your %path%

For tracing, put the wrapper next to game's executable. It will look for glide2x.dll in the parent directory, so put your wrapper dll there. Captured data will be written to trace.bin file.
Glide2x_retrace reads the path to the wrapper from the glide2x_retrace.ini configuration file.
Don't let it load the tracing wrapper, it will not work.


Todo
-----------

* find test cases for the few unimplemented functions
* gui for frame inspection
* trace compression
* test on real 3dfx boards


Thanks
-----------
* authors of various glide wrappers
* apitrace for the idea and being a great tool
* the 3dfx guys: https://www.youtube.com/watch?v=3MghYhf-GhU and others