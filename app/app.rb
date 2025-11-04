require "sinatra"

set :bind, "0.0.0.0"
set :port, (ENV["PORT"] || 3000)

get "/" do
  "Hello from rails-ecs minimal app 👋"
end

get "/health" do
  status 200
  "ok"
end
