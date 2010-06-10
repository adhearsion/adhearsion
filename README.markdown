Adhearsion
==========

Adhearsion is an open-source voice application development framework. Adhearsion users write applications atop the framework with Ruby and **call into their code**.

Adhearsion rests above a lower-level telephony platform, namely [Asterisk](http://asterisk.org), though there are experimental bindings for both [FreeSWITCH](http://freeswitch.org) and [Yate](http://yate.null.ro/pmwiki).

Adhearsion has...

* An elegant dialplan system for writing the code which controls a live phone call
* A sophisticated Asterisk Manager Interface library with a lexer written in [Ragel](http://www.complang.org/ragel).
* An events subsystem which maintains a Thread-pool for executing your namespaced callbacks. (supports AMI events too!)
* A very useful component architecture with which you may write Adhearsion plugins and share them with the world.
* JRuby compatibility for running atop the Java Virtual Machine and using virtually any Java library.
* Good regression test coverage

bklang's fork
=============

This fork of the official Adhearsion repository is intended to be a place where we, the Adhearsion community, can collect patches and fixes that have not yet been merged upstream.  Note that this fork in particular works with Asterisk version 1.6 and later, and is broken with all earlier versions (including Asterisk 1.4!).  The hope is that with additional testing from the community, Jay and Jason will merge some or all of these changes into the official repository at some date in the future.

For discussion of these changes, please visit the irc channel:
irc.freenode.net #adhearsion

or post on the Adhearsion mailing list:
http://groups.google.com/group/adhearsion

Documentation
=============

Visit [Adhearsion's website](http://adhearsion.com) for more information about the framework or visit the [wiki](http://docs.adhearsion.com) for documentation on how to use it.

If you're having trouble, you may want to try asking your question on the IRC channel, [mailing list](http://groups.google.com/group/adhearsion) or, if you've found a bug, report it on the [bug tracker](http://adhearsion.lighthouseapp.com/projects/5871-adhearsion/overview).
