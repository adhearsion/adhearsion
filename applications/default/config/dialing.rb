# NOTE: This file is a work in progress. It presently doesn't hook into
# anything yet.

# A VoIP "provider" is a service through which you can route VoIP calls.
# In this you specify both the provider-specific configuration options
# and, more importantly, the patterns used to dial them.

provider:fwd do |trunk|
  
end

provider:gizmo do |trunk|
  
  # username 'my_username'
  # password 'my_password'

  # Asterisk-specific configuration. This needs to be DSL-ified.
  # The Asterisk standard seems to handle many different customizations
  # and may be a good foundation on which the DSL is constructed. It
  # should be noted that the final DSL should work despite whether
  # Asterisk or Freeswitch is under the covers.
  
  # type=friend ; allows incoming and outgoing calls
  # host=dynamic
  # dtmfmode=rfc2833
  # canreinvite=yes
  # allowguest=yes
  # insecure=very
  # promiscredir=yes
end

route _('1767XXXXXXX') >> gizmo