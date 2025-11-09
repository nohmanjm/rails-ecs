require 'sinatra'
require 'json'


set :bind, '0.0.0.0'
set :port, ENV['PORT'] ? ENV['PORT'].to_i : 3000


get '/' do
  'Hello from the simple API.'
end


get '/health' do
  content_type :json
  status 200
  { status: 'ok_V2' }.to_json
end
