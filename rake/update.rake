namespace :cfn do

  desc "update"
  task :update => :init do

    # Execute the main template
    begin

      # Update the stack
      cmd = "bundle exec #{File.join($cfn_path,'main.rb')} update #{$cfn_stack_name}"
      pid, stdin, stdout, stderr = Open4::popen4 cmd
      ignored, status = Process::waitpid2 pid

      # Exit if command failed
      raise "Error executing #{cmd}: #{stderr.read}" if status.exitstatus != 0
      puts "INFO - Template update triggered for #{$cfn_stack_name}"

    rescue => e

      # Case where the environment is up to date
      if e.message.match(/No updates are to be performed/)
        puts "WARN - No updates are to be performed, stack is up to date"
        exit 0
      end

      puts "ERROR - failed to update template, error was:"
      puts e
      exit 1
    end
    
    # Validate the status and exit accordingly
    begin

      begin

        # Sanity sleep to not overflow the AWS API
        sleep AWS_SLEEP_TIME

        # Get the cfn stack status
        cmd = "bundle exec #{File.join($cfn_path,'main.rb')} describe #{$cfn_stack_name}"
        pid, stdin, stdout, stderr = Open4::popen4 cmd
        ignored, status = Process::waitpid2 pid

        # Check the status and raise if not CREATE_COMPLETE
        stack_status = JSON::parse(stdout.read)[$cfn_stack_name]['stack_status']
        raise stack_status if ['UPDATE_FAILED','UPDATE_ROLLBACK_COMPLETE'].include? stack_status

      end until stack_status == "UPDATE_COMPLETE"

      puts "INFO - Template update successfull"
    rescue => e
      puts "ERROR - failed to update template, error was:"
      puts e
      exit 1
    end

  end

end

