require 'aruba/cucumber'


def help

  message = <<EOF

Error: 

One or more of the following environment variables is not
defined. To test you can use the rake embedded project or
a custom one. To do so just run the lines above in the shell
and complete with the account credentials

  # Test project specific variables
  export EV_BUCKET_NAME=els-evise-nonprod-rake-cfn-build
  export EV_PROJECT_NAME=testproj
  export EV_ENVIRONMENT=test
  export EV_GIT_PATH=resources/test_app
  export EV_CREATE_IF_NOT_EXIST=true
  export EV_CFN_STACK_NAME=test-testproj-testapp
 
  # AWS credentials
  export AWS_ACCESS_KEY_ID=
  export AWS_SECRET_ACCESS_KEY=
  export AWS_DEFAULT_REGION=

EOF

  puts message

end

# Show help message if environment variables are not defined
%w(AWS_ACCESS_KEY_ID AWS_DEFAULT_REGION AWS_REGION AWS_SECRET_ACCESS_KEY
 EV_BUCKET_NAME EV_CFN_STACK_NAME EV_CREATE_IF_NOT_EXIST 
EV_ENVIRONMENT EV_GIT_PATH EV_PROJECT_NAME).each do |var|
  unless ENV.include? var
    help
    exit 1
  end
end

# Setup cucumber timeouts
Aruba.configure do |config|
  config.exit_timeout    = 60
  config.io_wait_timeout = 2
end
