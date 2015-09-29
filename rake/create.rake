namespace :cfn do

  desc 'Create an environment using Cloud formation'
  task :create => :upload do

    ######################################################################
    # Environment variables / task parameters

    application_name = ENV['EV_APPLICATION_NAME'] || fail('error: EV_APPLICATION_NAME not defined')

    project_name = ENV['EV_PROJECT_NAME'] || fail('error: EV_PROJECT_NAME not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')

    ######################################################################
    # Variables definitions and validations

    cfn_stack_name = "#{environment}-#{project_name}-#{application_name}"

    rubycfndsl_path = File.join(application_path, 'rubycfndsl')

    ######################################################################
    # Execute the main template

    begin
      # Create the stack
      cmd = "bundle exec #{File.join(rubycfndsl_path, 'main.rb')} create #{cfn_stack_name}"
      pid, _stdin, _stdout, stderr = Open4.popen4 cmd
      _ignored, status = Process.waitpid2 pid

      # Exit if command failed
      fail "Error executing #{cmd}: #{stderr.read}" if status.exitstatus != 0
      puts "INFO: Template create triggered for #{cfn_stack_name}"
    rescue => e
      puts 'ERROR: failed to create template, error was:'
      puts e
      exit 1
    end

    ######################################################################
    # Loop until the template is created

    begin
      loop do
        # Sanity sleep to not overflow the AWS API
        sleep AWS_SLEEP_TIME

        # Get the cfn stack status
        cmd = "bundle exec #{File.join(cfn_template_path, 'main.rb')} describe #{cfn_stack_name}"
        pid, _stdin, stdout, _stderr = Open4.popen4 cmd
        _ignored, _status = Process.waitpid2 pid

        # Check the status and fail if not CREATE_COMPLETE
        stack_status = JSON.parse(stdout.read)[cfn_stack_name]['stack_status']
        fail if %w(CREATE_FAILED ROLLBACK_COMPLETE).include? stack_status
        break if stack_status == 'CREATE_COMPLETE'
      end

      puts 'INFO: Template create successfull'
    rescue => e
      puts 'ERROR: failed to create template, error was:'
      puts e
      exit 1
    end

  end

end
