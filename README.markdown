# Adhearsion

Adhearsion is an open-source voice application development framework. Adhearsion users write applications atop the framework with Ruby and **call into their code**.

Adhearsion rests above a lower-level telephony platform, for example [Asterisk](http://asterisk.org) or [Voxeo PRISM](http://voxeolabs.com/prism/), and provides a framework for integrating with various resources, such as SQL, LDAP and XMPP (Jabber).

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

* Ruby 1.9.2+ or JRuby 1.6.7+
* A VoIP platform:
  * Asterisk 1.8+
  * FreeSWITCH
  * Prism 11+ with rayo-server
* An interest in building cool new things

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

## Author

Core team:

* [Ben Klang](https://github.com/bklang)
* [Ben Langfeld](https://github.com/benlangfeld)
* [Jason Goecke](https://github.com/jsgoecke)

Contributors: https://github.com/adhearsion/adhearsion/contributors

Original author: [Jay Phillips](https://github.com/jicksta)

### Contributions

Adhearsion has a set of [contribution guidelines](https://github.com/adhearsion/adhearsion/wiki/Contributing) which help to smooth the contribution process.
There is a pre-commit hook that runs encoding checks available in pre-commit. To use it, please copy it to .git/hooks/pre-commit and make it executable.

### Copyright

Copyright (c) 2012 Adhearsion Foundation Inc. MIT LICENSE (see LICENSE for details).
