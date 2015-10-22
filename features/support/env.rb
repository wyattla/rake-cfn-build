require 'aruba/cucumber'

# Display context specific error if environment variables are not defined
%w(AWS_ACCESS_KEY_ID AWS_DEFAULT_REGION AWS_SECRET_ACCESS_KEY
 EV_BUCKET_NAME EV_CREATE_IF_NOT_EXIST 
EV_ENVIRONMENT EV_GIT_PATH EV_PROJECT_NAME).each do |var|
  unless (ENV.include? var) && (ENV[var] != "")
    puts "Required environment variable #{var} is empty or not defined."
    exit 1
  end
end

# Setup cucumber timeouts
Aruba.configure do |config|
  config.exit_timeout    = 60
  config.io_wait_timeout = 2
end
