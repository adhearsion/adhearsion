require 'sinatra'

set :root, Adhearsion.root

get '/' do
  'Hello world!'
end

run Sinatra::Application
