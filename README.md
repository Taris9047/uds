1. Introduction
   Utility installation script for my use. Sometimes, installing Unix or Linux utilities is not straightforward and time consuning to figure out the 'best' complation condition and options. So, this project began as my personal implementation of FreeBSD's pkg or Gentoo's emerge package manager. In fact, I've tried to almost carbon copy the OS X's Homebrew. 
	
2. Structure
   Simply put, everything could have done with a Ruby script. But I thought using Python for front-end part of the system since my experience with PyQt implementations I have worked before. Also, Ruby's GUI API libraries are not very popular except Rails and Ruby-on-Rails is a web application rather than a lightweight program that this project aims for. GUI part of front-end is still TBD to even start implementation, though!
   
   The main script that does download, compile, and installation are written by Ruby. I've started using Ruby since Homebrew project also uses it and I had motivation to learn a new language while working with this project. And it seems to be a successful choice since Ruby is a versatile and flexible language in terms of working with system related tasks. Especially Ruby's ample way of manipulating strings and paths were really helpful!
   
   There are a few Org-mode based shell scripts to install Wine on RHEL and Debian. They may be implemented into the main script later. But Org-mode based shell scripts are great as their own, anyway.
   
3. To use this script, we need following.
   A. Well known Linux distribution: Ubuntu, Red Hat Enterprise Linux, Fedora, Manjaro are currently tested platforms.
   B. Git: Some packages need git to download.
   C. Ruby: Obviously, the backend runs with Ruby. Required gems will be installed via prerequisite installation.
   D. Python3: Front-end runs with Python. I believe no one would dare to use Python2, right?
   
4. For now, most of packages install without too much of problem. But these kind of tasks usually are extremely dependent on the system settings which are never the same. So, be sure to cope with a lot of breakages!


