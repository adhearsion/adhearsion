class BlankSlate
  (instance_methods - [:instance_eval, :object_id]).each { |m| undef_method m unless m.to_s =~ /^__/ }
end
