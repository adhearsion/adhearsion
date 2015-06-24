require 'sinatra'

get '/' do
  'Hello world!'
end

run Sinatra::Application
