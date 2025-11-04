Rails.application.routes.draw do
  # Simple JSON health endpoint
  get "/health", to: proc { [200, { "Content-Type" => "application/json" }, ['{"status":"ok"}']] }

  # Built-in Rails health check
  get "up" => "rails/health#show", as: :rails_health_check
end
