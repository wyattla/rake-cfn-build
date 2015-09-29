namespace :cfn do

  desc 'Delete a stack using cloud formation template'
  task :delete => :init do

    ######################################################################
    # Environment variables / task parameters

    application_name = ENV['EV_APPLICATION_NAME'] || fail('error: EV_APPLICATION_NAME not defined')

    project_name = ENV['EV_PROJECT_NAME'] || fail('error: EV_PROJECT_NAME not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')

    git_path = ENV['EV_GIT_PATH'] || fail('error: no EV_GIT_PATH not defined')

    ######################################################################
    # Variables definitions and validations

    cfn_stack_name = "#{environment}-#{project_name}-#{application_name}"

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
      puts "INFO: Template delete triggered for #{cfn_stack_name}"

    rescue => e
      puts 'ERROR: failed to delete template, error was:'
      puts e
      exit 1
    end

  end

end
