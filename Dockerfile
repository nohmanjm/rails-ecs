# --- Stage 1: Builder Stage (For installing gems) ---
FROM ruby:3.3-slim AS builder

ENV APP_HOME=/app
WORKDIR $APP_HOME

# Install packages needed for gem compilation
RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Copy Gemfile and Lockfile (Flat structure at root)
COPY Gemfile Gemfile.lock ./ 

# *** CRITICAL: Explicitly set the installation path for Bundler. ***
# This makes it easy to reference in the next stage.
ENV BUNDLE_PATH=/usr/local/bundle

# Install gems into the defined BUNDLE_PATH
RUN bundle config set deployment 'true' \
 && bundle config set without 'development test' \
 && bundle install --jobs 4 --retry 3

# --- Stage 2: Production/Runtime Stage (Minimal and Secure) ---
FROM ruby:3.3-slim AS production

ENV APP_HOME=/app
ENV RACK_ENV=production
ENV PORT=3000

# *** CRITICAL FIX BLOCK ***
# 1. Define the installation path again (MUST match builder)
ENV BUNDLE_PATH=/usr/local/bundle
# 2. **The Missing Piece:** Add the Bundler executable directory to the shell's PATH.
# This ensures 'bundle exec puma' can find the 'bundle' executable.
ENV PATH=$BUNDLE_PATH/bin:$PATH
# *** END CRITICAL FIX BLOCK ***

WORKDIR $APP_HOME

# Install minimal runtime dependencies (netcat for healthchecks)
RUN apt-get update -qq && apt-get install -y --no-install-recommends netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Copy only the installed gems from the builder stage
COPY --from=builder $BUNDLE_PATH $BUNDLE_PATH

# Copy all application files required for runtime
COPY Gemfile Gemfile.lock config.ru app.rb ./

EXPOSE 3000

# --- Stage 2: Production/Runtime Stage (Minimal and Secure) ---
# ... (rest of the file remains the same, including the PATH fix)
# ...

# Copy all application files required for runtime
COPY Gemfile Gemfile.lock config.ru app.rb ./

EXPOSE 3000

# *** FIX: Simplified CMD to avoid argument parsing issues ***
# Puma will automatically pick up PORT=3000 and RACK_ENV=production
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000", "config.ru"]
