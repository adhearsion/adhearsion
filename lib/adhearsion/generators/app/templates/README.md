# Welcome to Adhearsion

You've got a fresh app and you're almost ready to get started. Firstly, you'll need to configure your VoIP platform:

## Asterisk

Edit `extensions.conf` to include the following:

```
[your_context_name]
exten => _.,1,AGI(agi:async)
```

and setup a user in `manager.conf` with read/write access to `all`.

## Voxeo PRISM

Install the [rayo-server](https://github.com/rayo/rayo-server) app into PRISM 11 and follow the [configuration guide](https://github.com/rayo/rayo-server/wiki/Single-node-and-cluster-configuration-reference).

## Configure your app

In `config/adhearsion.rb` you'll need to set the VoIP platform you're using, along with the correct credentials. You'll find example config there, so follow the comments.

## Ready, set, go!

Start your new app with "ahn start /path/to/your/app". You'll get a lovely console and should be presented with the SimonGame

Check out [the Adhearsion website](http://adhearsion.com) for more details of where to go from here.
