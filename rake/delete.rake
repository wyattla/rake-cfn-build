namespace :cfn do

  desc 'Delete a stack using cloud formation template'
  task :delete => :init do

    ######################################################################
    # Environment variables / task parameters

    application = ENV['EV_APPLICATION'] || fail('error: EV_APPLICATION not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')

    git_path = ENV['EV_GIT_PATH'] || fail('error: no EV_GIT_PATH not defined')

    cfn_stack_name = ENV['EV_CFN_STACK_NAME'] || "#{application}-#{environment}" 

    ######################################################################
    # Variables definitions and validations

    rubycfndsl_path = File.join(git_path, 'rubycfndsl')

    ######################################################################
    # Delete the stack

    begin

      # Delete stack
      cmd = "bundle exec #{File.join(rubycfndsl_path, 'main.rb')} delete #{cfn_stack_name}"
      pid, stdin, _stdout, stderr = Open4.popen4 cmd
      stdin.puts 'y'
      _ignored, status = Process.waitpid2 pid

      # Exit if command failed
      fail "ERROR: failed to executing #{cmd}: \n\n #{stderr.read}" if status.exitstatus != 0
      puts "INFO: Template delete triggered for #{cfn_stack_name}\n\n"

      # Invoke cfn:get_cfn_events to monitor the logs
      Rake::Task["cfn:get_cfn_events"].invoke

    rescue => e
      puts 'ERROR: failed to delete template, error was:'
      puts e
      exit 1
    end

    ######################################################################
    # Verify if stack has been deleted

    begin

      # Sanity sleep to not overflow the AWS API
      sleep AWS_SLEEP_TIME

      # Get the list of stacks and ask for status
      cfn = Aws::CloudFormation::Client.new
      response = cfn.describe_stacks(stack_name: cfn_stack_name)
      break if response.stacks.size == 0
      fail 'DELETE_FAILED' if %w(DELETE_FAILED).include? response.stacks.first.stack_status

    rescue => e
      unless e.message.match(/Stack with id .* does not exist/)
        puts 'ERROR: failed to get a list of stacks, error was:'
        puts e
      end
    end
    puts 'INFO: Stack has been deleted'
  end

end
