class BlankSlate
  (instance_methods - %w{instance_eval object_id}).each { |m| undef_method m unless m =~ /^__/ }
end