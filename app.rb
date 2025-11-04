require 'sinatra'
require 'json'

# Ensure the server binds to all interfaces and uses the PORT environment variable
set :bind, '0.0.0.0'
set :port, ENV['PORT'] ? ENV['PORT'].to_i : 3000

# Root endpoint (optional, but good practice)
get '/' do
  'Hello from the simple API.'
end

# Required /health endpoint
get '/health' do
  content_type :json
  status 200
  { status: 'ok' }.to_json
end
