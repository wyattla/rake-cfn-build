# Requires:
require 'pp'
require 'aws-sdk'
require 'pry'
require 'open4'

# Disable stdout buffer
STDOUT.sync = true

# Include substasks from different namespaces
Dir.glob('*/*rake').map { |rake| import rake }
