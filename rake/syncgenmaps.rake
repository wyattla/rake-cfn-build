namespace :cfn do

  desc 'Sync generic maps to s3'
  task :syncgenmaps => :init do

    ######################################################################
    # Environment variables / task parameters

    bucket_name = 'entvpc-infrastructure'

    application = 'global_framework'

    environment = 'prod'

    git_path = '../common/global_framework'

    ######################################################################
    # Variables definitions and validations

    maps_path = File.join(git_path, 'maps')
    maps_files = Dir.glob(File.join(maps_path, '*rb')).map do |x|
      File.expand_path x
    end

    fail "ERROR: No maps found on #{maps_path}" if maps_files.empty?

    s3 = Aws::S3::Resource.new

    ######################################################################
    # Upload all the cloud formation templates to the s3 bucket

    begin

      maps_files.each do |file|

        # Variables:
        file_name = file.split('/').last
        file_key = File.join(application, environment, 'maps', file_name)

#        # Generate json template:
#        cmd = "bundle exec #{file} expand > tmp/#{file_name}"
#        pid, _stdin, _stdout, stderr = Open4.popen4 cmd
#        _ignored, status = Process.waitpid2 pid
#        if status.exitstatus != 0
#          fail "Error creating json template on #{file} \n#{stderr.read}"
#        end

        # Upload json template to s3
        obj = s3.bucket(bucket_name).object(file_key)
        obj.upload_file(file)

      end

      s3_cfn_location = File.join(bucket_name, application, environment, 'cloudformation')
      puts "INFO: Cloud formation templates uploaded to s3://#{s3_cfn_location}"

    rescue => e
      puts "ERROR: failed to upload templates to s3://#{s3_cfn_location}, error was:"
      puts e
      exit 1
    end

  end

end
