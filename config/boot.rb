ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup"
require "logger" # Explicit require needed for Rails 6.1 + Ruby 3.1 compatibility
