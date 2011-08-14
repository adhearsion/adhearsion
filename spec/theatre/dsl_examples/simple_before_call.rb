=begin YAML
namespaces:
  - ["asterisk", "before_call"]
=end
events.asterisk.before_call.each do |call|
  call.variables[:channel]
end