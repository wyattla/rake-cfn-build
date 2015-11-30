# Requires:
require 'pp'
require 'aws-sdk'
require 'pry'
require 'open4'
require 'colorize'

# Use AWS-SDK's bundled cert to avoid SSL errors
Aws.use_bundled_cert!

# Disable stdout buffer
STDOUT.sync = true

# Include substasks from different namespaces
Dir.glob('rake/*.rake').map { |rake| import rake }
