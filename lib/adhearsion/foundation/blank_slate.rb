class BlankSlate
  (instance_methods.map{|m| m.to_sym} - [:instance_eval, :object_id]).each { |m| undef_method m unless m.to_s =~ /^__/ }
end
