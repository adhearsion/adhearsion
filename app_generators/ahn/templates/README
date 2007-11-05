Start your new app with "ahn start #{dest_dir_relative}"

If you wish to use Adhearsion to control Asterisk's dialplan,
change the contexts you wish to be affected in your
/etc/asterisk/extensions.conf file to the following:

[your_context_name]
exten => _X.,1,AGI(agi://1.2.3.4) ; This IP here

To use databases, edit config/database.yml for the
connection information and, optionally, config/database.rb
to change the default database object models. To create your
tables, you may wish to use config/migration.rb.

Asterisk Manager interface integration is highly recommended.
Edit your /etc/asterisk/manager.conf file and enable the
system *securely* with an account for this app. Reload
with "asterisk -rx reload manager" and then edit the
config/helpers/manager_proxy.yml file appropriately.

If you would like a local copy of the Adhearsion wiki, run
"rake wiki" in your app folder. Please support the community
by contributing documentation improvements by visiting the
online, editable version at http://docs.adhearsion.com!