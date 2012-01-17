Adhearsion
===========

Adhearsion is an open-source voice application development framework. Adhearsion users write applications atop the framework with Ruby and **call into their code**.

Adhearsion rests above a lower-level telephony platform, for example [Asterisk](http://asterisk.org) or [Voxeo PRISM](http://voxeolabs.com/prism/), and provides a framework for integrating with various resources, such as SQL, LDAP and XMPP (Jabber).

Features
--------

* An elegant system of call controllers for writing the code which controls a live phone call.
* An events subsystem which maintains a Thread-pool for executing your namespaced callbacks.
* A very useful plugin architecture with which you may write Adhearsion plugins and share them with the world via RubyGems.
* JRuby compatibility for running atop the Java Virtual Machine and using virtually any Java library.
* Ability to re-use existing Ruby on Rails database models with ActiveRecord/ActiveLDAP
* Easy interactive communication via XMPP instant messages using the Blather library
* Strong test coverage
* Much more

Requirements
------------

* Ruby 1.9.2+ or JRuby 1.6.5+
* A VoIP platform:
  * Asterisk 1.8+
  * Prism 11+ with rayo-server
* An interest in building cool new things

Install
-------

`gem install adhearsion`

Examples
--------

An Adhearsion application can be as simple as this:

```ruby
answer
speak 'Hello, and thank you for your call. We will put you through to the front desk now...'
dial 'tel:+18005550199'
hangup
```

For more examples, check out [the website](http://adhearsion.com/examples).

Documentation
=============

Visit [Adhearsion's website](http://adhearsion.com) for code examples and more information about the project. Also checkout the [Adhearsion wiki on Github](http://github.com/adhearsion/adhearsion/wiki) for community documentation.

If you're having trouble, you may want to try asking your question on the IRC channel (#adhearsion on irc.freenode.net), [mailing list](http://groups.google.com/group/adhearsion) or, if you've found a bug, report it on the [bug tracker](https://github.com/adhearsion/adhearsion/issues).

Author
------

Original author: [Jay Phillips](https://github.com/jicksta)

Core team:

* [Ben Klang](https://github.com/bklang)
* [Ben Langfeld](https://github.com/benlangfeld)
* [Jason Goecke](https://github.com/jsgoecke)

Contributors: https://github.com/adhearsion/adhearsion/contributors

Contributions
-----------------------------

Adhearsion has a set of [contribution guidelines](https://github.com/adhearsion/adhearsion/wiki/Contributing) which help to smooth the contribution process.

Copyright
---------

Copyright (c) 2011 Individual contributors. GNU LESSER GENERAL PUBLIC LICENSE (see LICENSE for details).
