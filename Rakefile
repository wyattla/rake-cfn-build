# Requires:
require 'pp'
require 'aws-sdk'
require 'pry'
require 'open4'
require 'colorize'
require 'table_print'

# Use AWS-SDK's bundled cert to avoid SSL errors
Aws.use_bundled_cert!

# Disable stdout buffer
STDOUT.sync = true

# Include sub-tasks from different namespaces
glob_paths = ["./rake"] # default
if ENV.has_key?('EV_GIT_PATH') && File.directory?(ENV['EV_GIT_PATH'])
  glob_paths << "#{ENV['EV_GIT_PATH']}/rake"
end

glob_paths.each do |path|
  Dir.glob("#{path}/*.rake").map { |rake| import rake }
end
