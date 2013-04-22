# Welcome to Adhearsion

You've got a fresh app and you're almost ready to get started. Firstly, you'll need to configure your VoIP platform:

## Asterisk

Edit `extensions.conf` to include the following:

```
[your_context_name]
exten => _.,1,AGI(agi:async)
```

and setup a user in `manager.conf` with read/write access to `all`.

If you are using Asterisk 1.8, you will need to add an additional context with the name `adhearsion-redirect`. On Asterisk 10 and above this is auto-provisioned.

## FreeSWITCH

* Ensure that mod_event_socket is installed, and configure it in autoload_configs/event_socket.conf.xml to taste
* Add an extension to your dialplan like so:

```xml
<extension name='Adhearsion'>
  <condition field="destination_number" expression="^10$">
    <action application="set" data="hangup_after_bridge=false"/>
    <action application="set" data="park_after_bridge=true"/>
    <action application='park'/>
  </condition>
</extension>
```

## Voxeo PRISM

Install the [rayo-server](https://github.com/rayo/rayo-server) app into PRISM 11 and follow the [configuration guide](https://github.com/rayo/rayo-server/wiki/Single-node-and-cluster-configuration-reference).

## Configure your app

In `config/adhearsion.rb` you'll need to set the VoIP platform you're using, along with the correct credentials. You'll find example config there, so follow the comments.

## Ready, set, go!

Start your new app with "ahn start". You'll get a lovely console and should be presented with the SimonGame when you call in.

### Running your app on heroku

In order to run an adhearsion application on Heroku, you must create the application on the 'cedar' stack (`heroku apps:create --stack cedar`) and re-scale your processes like so:

```
heroku ps:scale web=0
heroku ps:scale ahn=1
```

More detail is available in the [deployment documentation](http://adhearsion.com/docs/best-practices/deployment).

Check out [the Adhearsion website](http://adhearsion.com) for more details of where to go from here.
