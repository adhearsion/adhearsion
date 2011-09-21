# A sample Guardfile
# More info at https://github.com/guard/guard#readme

ENV['SKIP_RCOV'] = 'true'
group 'adhearsion' do

  guard 'rspec', :version => 2, :cli => '--format documentation' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb')  { "spec/" }
  end

end

group 'punchblock:main' do

  guard 'rspec', :version => 2, :cli => '--format documentation', :spec_paths => ['spec/adhearsion/punchblock'] do
    watch(%r{^spec/adhearsion/punchblock/.+_spec\.rb$})
    watch(%r{^lib/adhearsion/punchblock/(.+)\.rb$}) { |m| "spec/adhearsion/punchblock/#{m[1]}_spec.rb"}
  end

end

group 'punchblock:commands' do

  guard 'rspec', :version => 2, :cli => '--format documentation', :spec_paths => ['spec/adhearsion/punchblock/commands'] do
    watch(%r{^spec/adhearsion/punchblock/commands/.+_spec\.rb$})
    watch(%r{^lib/adhearsion/punchblock/commands/(.+)\.rb$}) { |m| "spec/adhearsion/punchblock/commands/#{m[1]}_spec.rb"}
  end

end

group 'punchblock:menu' do

  guard 'rspec', :version => 2, :cli => '--format documentation', :spec_paths => ['spec/adhearsion/punchblock/menu'] do
    # watch(%r{^spec/adhearsion/punchblock/menu/.+_spec\.rb$})
    watch(%r{/.+_spec\.rb$})
    watch(%r{^lib/adhearsion/punchblock/menu/(.+)\.rb$}) { |m| "spec/adhearsion/punchblock/menu/#{m[1]}_spec.rb"}
  end

end
