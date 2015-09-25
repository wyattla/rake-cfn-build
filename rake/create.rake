namespace :cfn do

  desc "Create"
  task :create => :upload do

    # Execute the main template
    begin

      # Create the stack
      cmd = "bundle exec #{File.join($cfn_template_path,'main.rb')} create #{$cfn_stack_name}"
      pid, stdin, stdout, stderr = Open4::popen4 cmd
      ignored, status = Process::waitpid2 pid

      # Exit if command failed
      raise "Error executing #{cmd}: #{stderr.read}" if status.exitstatus != 0
      puts "INFO - Template create triggered for #{$cfn_stack_name}"

    rescue => e
      puts "ERROR - failed to create template, error was:"
      puts e
      exit 1
    end
    
    begin
      # Validate the status and exit accordingly
      begin

        # Sanity sleep to not overflow the AWS API
        sleep AWS_SLEEP_TIME

        # Get the cfn stack status
        cmd = "bundle exec #{File.join($cfn_template_path,'main.rb')} describe #{$cfn_stack_name}"
        pid, stdin, stdout, stderr = Open4::popen4 cmd
        ignored, status = Process::waitpid2 pid

        # Check the status and raise if not CREATE_COMPLETE
        stack_status = JSON::parse(stdout.read)[$cfn_stack_name]['stack_status']
        raise "" if ['CREATE_FAILED','ROLLBACK_COMPLETE'].include? stack_status

      end until stack_status == "CREATE_COMPLETE"

      puts "INFO - Template create successfull"
    rescue => e
      puts "ERROR - failed to create template, error was:"
      puts e
      exit 1
    end

  end

end

