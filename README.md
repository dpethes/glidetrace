Glide trace
===========

Glide2x call (re)tracing. Inspired by ApiTrace https://apitrace.github.io

The wrapper captures all glide calls to a file and then forwards the calls to the real glide2x wrapper.
Glide2x_retrace can replay the calls afterwards, even on different glide wrappers (but beware, if the emulated boards are different, there may be some graphics corruption).
It can be used for debugging or performance tuning of wrappers, function call inspection or just plain fun - as a tool for replaying your favourite games.


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
* some libs for retrace (put the dll-s next to glide2x_retrace or to your %path%)
  * SDL 1.2, https://libsdl.org
  * cimgui, https://github.com/dpethes/imgui-pas

For tracing, put the wrapper next to game's executable. It will look for glide2x.dll in the parent directory, so put your wrapper dll there. Captured data will be written to trace.bin file. The tracing increases cpu load and needs steady disk bandwith of several MB/s, so it may slow down the games considerably if run on an old-timer pc.

Glide2x_retrace reads the path to the wrapper from the glide2x_retrace.ini configuration file.
Don't let it load the tracing wrapper, it will not work unless you rename the input trace file (both on disk and in the project).


Todo
-----------
* trace LFB writes
* find test cases for the few unimplemented functions
* optimize wrapper's memory usage
* gui for frame inspection
* test on real 3dfx boards


Tested games
-----------
* Tomb Raider - ok
* Unreal Tournament - ok, can overwrite GUI
* Star Wars: Rogue Squadron 3D - ok, but the menu is missing (needs LFB write tracking)
* Homeworld (GoG edition) - ok, but needs 3Dfx OpenGl Driver version Beta 2.0/2.1, asteroids have bad culling mode (driver bug?)
* GLQuake - ok, but needs 3Dfx OpenGL Driver + dgVoodoo to run (couldn't get minigl working with glide wrappers)


Thanks
-----------
* authors of various glide wrappers
* apitrace https://github.com/apitrace/apitrace for the idea and being a great tool
* imgui https://github.com/ocornut/imgui
* the 3dfx guys: https://www.youtube.com/watch?v=3MghYhf-GhU and others
