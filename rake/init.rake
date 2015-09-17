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

    # Env variables definition:
    $bucket_name = ENV['CFN_BUCKETNAME'] || raise('error: CFN_BUCKETNAME not defined')
    $application_name = ENV['CFN_APPLICATIONNAME'] || raise('error: CFN_APPLICATIONNAME not defined')
    $project_name = ENV['CFN_PROJECTNAME'] || raise('error: CFN_PROJECTNAME not defined')
    $environment = ENV['CFN_ENVIRONMENT'] || raise('error: no CFN_ENVIRONMENT not defined')
    $cfn_path = ENV['CFN_TEMPLATE_PATH'] || raise('error: no CFN_ENVIRONMENT not defined')
    $cfn_create_if_not_exist = ENV['CFN_CREATE_IF_NOT_EXIST'].nil? ? false : ENV['CFN_CREATE_IF_NOT_EXIST']

    # Variables
    $stack_name = $project_name + '-' + $application_name
    $cfn_templates = Dir.glob(File.join($cfn_path,'*rb')).map {|x| File.expand_path x }
    $cfn_stack_name = $environment + '-' + $stack_name

    # Validations
    exit 1 if $cfn_templates.empty?

    # Upload all the cloud formation templates on CFN_BUCKETNAME
    begin

      s3 = Aws::S3::Resource.new

      $cfn_templates.each do |template|

        # Variables:
        template_name = template.split('/').last
        template_json_name = template_name.split('.').first + '.json'
        template_key = File.join($stack_name,template_json_name)
        
        # Generate json template:
        cmd = "bundle exec #{template} expand > tmp/#{template_json_name}"
        pid, stdin, stdout, stderr = Open4::popen4 cmd
        ignored, status = Process::waitpid2 pid
        raise "Error creating json template on #{template} \n#{stderr.read}" if status.exitstatus != 0

        # Upload json template to s3
        obj = s3.bucket($bucket_name).object(template_key)
        obj.upload_file(File.join('tmp',template_json_name))

      end

      puts "INFO - Templates uploaded to s3://#{$bucket_name}/#{$stack_name}"

    rescue => e
      puts "ERROR - failed to upload templates to s3, error was:"
      puts e
      exit 1
    end

  end

end
