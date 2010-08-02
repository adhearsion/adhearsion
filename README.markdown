Adhearsion
==========

Adhearsion is an open-source voice application development framework. Adhearsion users write applications atop the framework with Ruby and **call into their code**.

Adhearsion rests above a lower-level telephony platform, namely [Asterisk](http://asterisk.org), and provides a framework for integrating with various resources, such as SQL, LDAP and XMPP (Jabber).

Adhearsion has...

* An elegant dialplan system for writing the code which controls a live phone call
* A sophisticated Asterisk Manager Interface library with a lexer written in [Ragel](http://www.complang.org/ragel).
* An events subsystem which maintains a Thread-pool for executing your namespaced callbacks. (supports AMI events too!)
* A very useful component architecture with which you may write Adhearsion plugins and share them with the world.
* JRuby compatibility for running atop the Java Virtual Machine and using virtually any Java library.
* Ability to re-use existing Ruby on Rails database models with ActiveRecord/ActiveLDAP
* Easy interactive communication via XMPP instant messages using the Blather library
* Good regression test coverage

Use the public Adhearsion sandbox!
==================================

Don't want to screw with setting up a telephony system? You can test your Adhearsion applications using our public sandbox!

Visit [http://adhearsion.com/getting_started](http://adhearsion.com/getting_started) for more information!

Yes, in minutes you can be controlling your cell phone for free!  :)

Documentation
=============

Visit [Adhearsion's website](http://adhearsion.com) for more information about the framework or visit the [wiki](http://docs.adhearsion.com) for documentation on how to use it.

If you're having trouble, you may want to try asking your question on the IRC channel (#adhearsion on irc.freenode.net), [mailing list](http://groups.google.com/group/adhearsion) or, if you've found a bug, report it on the [bug tracker](http://adhearsion.lighthouseapp.com/projects/5871-adhearsion/overview).
