=begin YAML
namespaces:
  - ["before_call"]
=end
events.before_call.each do |call|
  call.variables[:channel]
end