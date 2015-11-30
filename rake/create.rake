namespace :cfn do

  desc 'Create an environment using Cloud formation'
  task :create => :upload do

    ######################################################################
    # Environment variables / task parameters

    application = ENV['EV_APPLICATION'] || fail('error: EV_APPLICATION not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')

    git_path = ENV['EV_GIT_PATH'] || fail('error: no EV_GIT_PATH not defined')

    cfn_stack_name = ENV['EV_CFN_STACK_NAME'] || "#{application}-#{environment}" 

    ######################################################################
    # Variables definitions and validations

    rubycfndsl_path = File.expand_path File.join(git_path, 'rubycfndsl')

    ######################################################################
    # Execute the main template

    begin
      # Create the stack
      cmd = "bundle exec #{File.join(rubycfndsl_path, 'main.rb')} create #{cfn_stack_name}"
      pid, _stdin, _stdout, stderr = Open4.popen4 cmd
      _ignored, status = Process.waitpid2 pid

      # Exit if command failed
      fail "Error executing #{cmd}: #{stderr.read}" if status.exitstatus != 0
      puts "INFO: Template create triggered for #{cfn_stack_name}\n\n"
    rescue => e
      puts 'ERROR: failed to create template, error was:'
      puts e
      exit 1
    end

    ######################################################################
    # Loop until the template is created

    begin

      # Invoke cfn:get_cfn_events to monitor the logs
      Rake::Task["cfn:get_cfn_events"].invoke

      # Get the cfn stack status
      cmd = "bundle exec #{File.join(rubycfndsl_path, 'main.rb')} describe #{cfn_stack_name}"
      pid, _stdin, stdout, _stderr = Open4.popen4 cmd
      _ignored, _status = Process.waitpid2 pid

      # Check the status and fail if not CREATE_COMPLETE
      stack_status = JSON.parse(stdout.read)[cfn_stack_name]['stack_status']
      fail if %w(CREATE_FAILED ROLLBACK_COMPLETE).include? stack_status
      puts 'INFO: Template create successful'
    rescue => e
      puts 'ERROR: failed to create template'
      exit 1
    end

  end

end
