namespace :cfn do
  desc 'Upload templates to s3'
  task upload: :init do
    # Env variables definition:
    $bucket_name = ENV['EV_BUCKET_NAME'] || fail('error: EV_BUCKET_NAME not defined')
    $application_name = ENV['EV_APPLICATION_NAME'] || fail('error: EV_APPLICATION_NAME not defined')
    $project_name = ENV['EV_PROJECT_NAME'] || fail('error: EV_PROJECT_NAME not defined')
    $environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')
    $application_path = ENV['EV_GIT_PATH'] || fail('error: no EV_GIT_PATH not defined')
    $cfn_create_if_not_exist = ENV['EV_CREATE_IF_NOT_EXIST'].nil? ? false : ENV['EV_CREATE_IF_NOT_EXIST']

    # Variables
    $cfn_stack_name = "#{$environment}-#{$project_name}-#{$application_name}"

    $rubycfndsl_path = File.join($application_path,'rubycfndsl')
    $rubycfndsl_files = Dir.glob(File.join($rubycfndsl_path,'*rb')).map {|x| File.expand_path x }

    $ans_playbooks_path = File.join($application_path,'ansible')
    $ans_playbooks = Dir.glob(File.join($ans_playbooks_path,'playbooks','*yml')).map {|x| File.expand_path x  unless x.match(/common/) }.compact

    s3 = Aws::S3::Resource.new

    # Validations
    if $rubycfndsl_files.empty?
      puts "WARNING - No templates found on #{$rubycfndsl_path}"
      exit 1
    end

    ################################################################################
    # Upload all the cloud formation templates to the s3 bucket
    begin


      $rubycfndsl_files.each do |file|

        # Variables:
        file_name = file.split('/').last
        template_cfn_name = file_name.split('.').first + '.template'
        template_key = File.join($project_name,$application_name,$environment,'cloudformation',template_cfn_name)
        
        # Generate json template:
        cmd = "bundle exec #{file} expand > tmp/#{template_cfn_name}"
        pid, stdin, stdout, stderr = Open4::popen4 cmd
        ignored, status = Process::waitpid2 pid
        fail "Error creating json template on #{file} \n#{stderr.read}" if status.exitstatus != 0

        # Upload json template to s3
        obj = s3.bucket($bucket_name).object(template_key)
        obj.upload_file(File.join('tmp',template_cfn_name))

      end

      puts "INFO - Cloud formation templates uploaded to s3://#{File.join($bucket_name,$project_name,$application_name,$environment,'cloudformation')}"

    rescue => e
      puts "ERROR - failed to upload templates to s3, error was:"
      puts e
      exit 1
    end

    ################################################################################
    # Create application roles and upload ansible playbooks to s3 bucket

    begin

      $ans_playbooks.each do |playbook|

        # Variables:
        role = File.basename(playbook).split('.').first
        tarfile = "ansible-playbook-#{role}.tar.gz"

        # Create tarfile:
        files = [
          "ansible.cfg",
          "playbooks/shared_vars",
          "playbooks/common.yml",
          "playbooks/#{role}.yml",
          "roles"
        ]
        system "cd #{$ans_playbooks_path} && tar zcf #{tarfile} #{files.join(' ')}"

        # Upload tarfile to s3
        tarfile_key = File.join($project_name,$application_name,$environment,'ansible',tarfile)

        # Upload each tarball to s3
        obj = s3.bucket($bucket_name).object(tarfile_key)
        obj.upload_file(File.join($ans_playbooks_path,tarfile))

      end

      puts "INFO - Ansible playbooks uploaded to s3://#{File.join($bucket_name,$project_name,$application_name,$environment,'ansible')}"

    rescue => e
      puts "ERROR - failed to upload ansible tarfile to s3, error was:"
      puts e
      exit 1
    end

  end

end
