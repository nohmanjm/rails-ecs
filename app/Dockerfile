FROM ruby:3.2-alpine

# Install required build tools for native gems
RUN apk add --no-cache build-base

# Set working directory
WORKDIR /app

# Copy and install Ruby gems
COPY Gemfile ./
RUN bundle config set without 'development test' && bundle install

# Copy application source
COPY . .

# Expose port and define default command
ENV PORT=3000
EXPOSE 3000
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "3000"]
