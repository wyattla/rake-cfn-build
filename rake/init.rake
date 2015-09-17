namespace :cfn do

  desc "Initialize"
  task :init do

    # Tmp directory
    FileUtils.rm_rf 'tmp'
    FileUtils.mkdir 'tmp'

    # Sleep time between api calls when waiting for status
    AWS_SLEEP_TIME = 2

    # AWS Credentials validation
    ENV['AWS_ACCESS_KEY_ID'] || raise('error: AWS_ACCESS_KEY_ID not defined')
    ENV['AWS_SECRET_ACCESS_KEY'] || raise('error: AWS_SECRET_ACCESS_KEY not defined')
    ENV['AWS_DEFAULT_REGION'] || raise('error: AWS_DEFAULT_REGION not defined')

  end

end
