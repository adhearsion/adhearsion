Adhearsion
==========

Adhearsion is an open-source voice application development framework. Adhearsion users write applications atop the framework with Ruby and **call into their code**.

Adhearsion rests above a lower-level telephony platform, namely [Asterisk](http://asterisk.org), and provides a framework for integrating with various resources, such as SQL, LDAP and XMPP (Jabber).

Adhearsion has...

* An elegant dialplan system for writing the code which controls a live phone call
* A sophisticated Asterisk Manager Interface library with a lexer written in [Ragel](http://www.complang.org/ragel).
* An events subsystem which maintains a Thread-pool for executing your namespaced callbacks. (supports AMI events too!)
* A very useful component architecture with which you may write Adhearsion plugins and share them with the world via RubyGems.
* JRuby compatibility for running atop the Java Virtual Machine and using virtually any Java library.
* Ability to re-use existing Ruby on Rails database models with ActiveRecord/ActiveLDAP
* Easy interactive communication via XMPP instant messages using the Blather library
* Good regression test coverage

Documentation
=============

Visit [Adhearsion's website](http://adhearsion.com) for code examples and more information about the project.  Also checkout the [Adhearsion wiki on Github](http://github.com/adhearsion/adhearsion/wiki) for community documentation.

If you're having trouble, you may want to try asking your question on the IRC channel (#adhearsion on irc.freenode.net), [mailing list](http://groups.google.com/group/adhearsion) or, if you've found a bug, report it on the [bug tracker](https://github.com/adhearsion/adhearsion/issues).
