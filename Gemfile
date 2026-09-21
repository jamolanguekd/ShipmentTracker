source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.6"

gem "rails", "~> 6.1.7"
gem "pg", "~> 1.3"
gem "puma", "~> 5.6"
gem "rack-cors"

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "rspec-rails", "~> 5.1"
  gem "factory_bot_rails"
  gem "shoulda-matchers", "~> 5.1"
end

group :test do
  gem "database_cleaner-active_record"
end
