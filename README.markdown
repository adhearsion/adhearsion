[![Gem Version](https://badge.fury.io/rb/adhearsion.svg)](https://rubygems.org/gems/adhearsion)
[![Build Status](https://secure.travis-ci.org/adhearsion/adhearsion.svg?branch=develop)](http://travis-ci.org/adhearsion/adhearsion)
[![Code Climate](https://codeclimate.com/github/adhearsion/adhearsion.svg)](https://codeclimate.com/github/adhearsion/adhearsion)
[![Coverage Status](https://coveralls.io/repos/adhearsion/adhearsion/badge.svg?branch=develop)](https://coveralls.io/r/adhearsion/adhearsion)
[![Inline docs](http://inch-ci.org/github/adhearsion/adhearsion.svg?branch=develop)](http://inch-ci.org/github/adhearsion/adhearsion)

# Adhearsion

Adhearsion is an open-source voice application development framework. Adhearsion users write applications atop the framework with Ruby and **call into their code**.

Adhearsion rests above a lower-level telephony platform, for example [Asterisk](http://asterisk.org), [FreeSWITCH](http://freeswitch.org) or [Voxeo PRISM](http://voxeolabs.com/prism/), and provides a framework for integrating with various resources, such as SQL, LDAP and XMPP (Jabber).

## Features

* Simple Ruby code
* Flexible CallControllers to handle calls
* High-level media handling constructs
* Simple interaction between calls
* Self-documenting configuration engine
* Support for plugins and other code reuse
* Integration with databases, web APIs, etc
* Event monitoring, async communication

## Requirements

* Ruby 2.2.0+ or JRuby 9.0.0.0+
* [ruby_speech dependencies](https://github.com/benlangfeld/ruby_speech#dependencies)
* A VoIP platform:
  * Asterisk 11+
  * FreeSWITCH 1.4+
* An interest in building cool new things

**Ruby 1.9 is no longer supported by Adhearsion or the Ruby core team. You should upgrade to Ruby 2.2 as a matter of urgency in order to continue receiving security fixes.**

## Install

`gem install adhearsion`

## Examples

An Adhearsion application can be as simple as this:

```ruby
answer
say 'Hello, and thank you for your call. We will put you through to the front desk now...'
dial 'tel:+18005550199'
hangup
```

For more examples, check out [the website](http://adhearsion.com/examples).

## Documentation

Visit [Adhearsion's website](http://adhearsion.com) for code examples and more information about the project. Also checkout the [Adhearsion wiki on Github](http://github.com/adhearsion/adhearsion/wiki) for community documentation.

If you're having trouble, you may want to try asking your question on the IRC channel (#adhearsion on irc.freenode.net), [mailing list](http://groups.google.com/group/adhearsion) or, if you've found a bug, report it on the [bug tracker](https://github.com/adhearsion/adhearsion/issues).

## Related Projects

These Open Source projects are also maintained by members of the Adhearsion team and may be useful when developing Adhearsion apps:

* [Telephony-Dev-Box](https://github.com/mojolingo/Telephony-Dev-Box) is a system for creating virtual machines that will preconfigure Adhearsion, Asterisk, FreeSWITCH and PRISM together.  Just add a SIP client and start calling your app!
* [SippyCup](https://github.com/bklang/sippy_cup) makes generating [SIPp](http://sipp.sourceforge.net/) profiles and RTP media easy.  Useful for load testing your apps and telephony infrastructure.

## Authors

Core team:

* [Ben Klang](https://github.com/bklang)
* [Ben Langfeld](https://github.com/benlangfeld)
* [Jason Goecke](https://github.com/jsgoecke)

Contributors: https://github.com/adhearsion/adhearsion/contributors

Original author: [Jay Phillips](https://github.com/jicksta)

### Contributions

Adhearsion has a set of [contribution guidelines](http://adhearsion.com/docs/contributing) which help to smooth the contribution process.
There is a pre-commit hook that runs encoding checks available in pre-commit. To use it, please copy it to .git/hooks/pre-commit and make it executable.

### Copyright

Copyright (c) 2011-2014 Adhearsion Foundation Inc. MIT LICENSE (see LICENSE for details).
