#!/bin/sh

set -e

for file in config/*.yml.example; do
  cp ${file} config/$(basename ${file} .example)
done

# Allow to override the Gitlab URL from an environment variable, as this will avoid having to change the configuration file for simple deployments.
config=$(echo '<% gitlab_url = URI(ENV["GITLAB_URL"] || "http://localhost:80") %>' | cat - config/gitlab.yml)
echo "$config" > config/gitlab.yml
sed -i "s/host: localhost/host: <%= gitlab_url.host %>/" config/gitlab.yml
sed -i "s/port: 80/port: <%= gitlab_url.port %>/" config/gitlab.yml
sed -i "s/https: false/https: <%= gitlab_url.scheme == 'https' %>/" config/gitlab.yml

cat > config/initializers/smtp_settings.rb << SMTP
smtp_url = URI(ENV['SMTP_URL']) rescue nil
if smtp_url
  Gitlab::Application.config.action_mailer.delivery_method = :smtp

  ActionMailer::Base.smtp_settings = {
    address: smtp_url.host,
    port: smtp_url.port,
    user_name: smtp_url.user,
    password: smtp_url.password,
    domain: smtp_url.path[1..-1],
    authentication: :login,
    enable_starttls_auto: true
  }
end
SMTP

# No need for config file. Will be taken care of by REDIS_URL env variable
rm config/resque.yml

# Set default unicorn.rb file
echo "" > config/unicorn.rb
