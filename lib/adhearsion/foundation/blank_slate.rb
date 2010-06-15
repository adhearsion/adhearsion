class BlankSlate
  instance_methods.each do |method|
    undef_method method unless method =~ /^__/ || method == 'instance_eval'
  end
end