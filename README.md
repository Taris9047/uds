Ruby is a must.

Make sure you install ruby with your own distro's packaging system. The script will not work without ruby 2.5 or newer.

* gcc4 causes some mishap due to its old library. So, its installation directory was separated to 'prefix'/.opt instead.
  The LDFLAGS has a lot of -rpath settings. So, it will work... 
  It was compiled due to stupid old CUDA anyway.


