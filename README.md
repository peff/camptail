camptail - a simple tail for campfire rooms
===========================================

Camptail is an absurdly simplistic tail-like program for tracking the
output of campfire rooms. It connects to the campfire server, looks at
each room you are currently in, outputs a configurable number of backlog
messages, and then goes into a loop, outputting any new messages that
are generated in any room.

Configuration
-------------

Camptail looks for configuration in the `.camptailrc` file in your
`$HOME` directory. This file is interpreted as perl, and you can set any
variable you like. The useful ones are:

  * $host -- the campfire host to connect to (e.g., use "foo" if you
    usually go to "foo.campfirenow.com")

  * $auth -- your auth token from the campfire site

  * $tail -- how many backlog messages to show for each room

  * $delay -- delay, in seconds, between poll of each room

  * $callback -- a reference to a subroutine to perform output; see
    below for details

Output
------

By default, camptail writes a text representation of each message to
stdout. However, you can override or augment this behavior by supplying
a custom perl callback function. The callback will receive a
Campfire::Message and a Campfire::Room object as its arguments.

A custom callback replaces the default print-on-stdout callback. To
chain to it, call `print_message(@_)`.  The callback is free to do
whatever it wants, including ignoring certain messages, printing them
differently, or performing some other action.

The message and room objects are currently not well documented; you'll
have to look at the source code for a list of methods.

Requirements
------------

Camptail uses the LWP, XML::Smart, and URI perl modules. You can install
them on Debian-ish systems with:

    sudo apt-get install libwww-perl libxml-smart-perl liburi-perl

Installation
------------

There is a build system, but it uses my as-yet-unreleased "mfm" makefile
creation tool. However, you can run it from the source directory with:

    perl camptail.pl

Author
------

Comments, suggestions, bug reports, and patches are welcome. Contact me
at <peff@peff.net>.
