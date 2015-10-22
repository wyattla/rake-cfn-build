namespace :cfn do

  desc 'Update an existing stack'
  task :update => :upload do

    ######################################################################
    # Environment variables / task parameters

    project_name = ENV['EV_PROJECT_NAME'] || fail('error: EV_PROJECT_NAME not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')

    create_if_not_exist = ENV['EV_CREATE_IF_NOT_EXIST'].nil? ? false : ENV['EV_CREATE_IF_NOT_EXIST']

    git_path = ENV['EV_GIT_PATH'] || fail('ERROR: no EV_GIT_PATH not defined')

    ######################################################################
    # Variables definitions and validations

    cfn_stack_name = "#{environment}-#{project_name}"

    rubycfndsl_path = File.join(git_path, 'rubycfndsl')

    ######################################################################
    # Verify if the stack exist, if not and requested, then trigger the create of it

    begin
      cfn = Aws::CloudFormation::Client.new
      stack = cfn.describe_stacks(stack_name: cfn_stack_name)
    rescue => e
      if e.message.match(/Stack with id .* does not exist/)
        stack = nil
      else
        puts 'ERROR: failed to get a list of stacks, error was:'
        puts e
      end
    end

    if create_if_not_exist && stack.nil?
      puts 'WARN: Environment does not exist, creating'
      Rake::Task['cfn:create'].invoke
      next
    end

    # Execute the main template
    begin

      # Update the stack
      cmd = "bundle exec #{File.join(rubycfndsl_path, 'main.rb')} update #{cfn_stack_name}"
      pid, _stdin, _stdout, stderr = Open4.popen4 cmd
      _ignored, status = Process.waitpid2 pid

      # Exit if command failed
      fail "Error executing #{cmd}: #{stderr.read}" if status.exitstatus != 0
      puts "INFO: Template update triggered for #{cfn_stack_name}\n\n"

    rescue => e

      # Case where the environment is up to date
      if e.message.match(/No updates are to be performed/)
        puts 'WARN: No updates are to be performed, stack is up to date'
        next
      end

      puts 'ERROR: failed to update template, error was:'
      puts e
      exit 1
    end

    # Validate the status and exit accordingly
    begin

      # Invoke cfn:get_cfn_events to monitor the logs
      Rake::Task["cfn:get_cfn_events"].invoke

      # Get the cfn stack status
      cmd = "bundle exec #{File.join(rubycfndsl_path, 'main.rb')} describe #{cfn_stack_name}"
      pid, _stdin, stdout, stderr = Open4.popen4 cmd
      _ignored, status = Process.waitpid2 pid

      # Check the status and fail if not CREATE_COMPLETE
      stack_status = JSON.parse(stdout.read)[cfn_stack_name]['stack_status']
      fail stack_status if %w(UPDATE_FAILED UPDATE_ROLLBACK_COMPLETE).include? stack_status
      puts 'INFO: Template update successfull'

    rescue => e
      puts 'ERROR: failed to update template, error was:'
      puts e
      exit 1
    end

  end

end
