require 'aruba/cucumber'

Aruba.configure do |config|
  config.exit_timeout    = 1200
  config.io_wait_timeout = 2
end
