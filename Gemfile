source 'https://rubygems.org'

gemspec

gem 'sinatra', require: nil
gem 'ruby_speech', github: 'adhearsion/ruby_speech'

group :test do
  # TODO: some expectations started failing in 3.8.3
  # The be_a_kind_of matcher requires that the actual object responds to either
  # #kind_of? or #is_a? methods  but it responds to neigher of two methods.
  gem 'rspec-expectations', '< 3.8.3'
end
