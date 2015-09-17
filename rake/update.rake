namespace :cfn do

  desc "update"
  task :update => :upload do

    # Verify if the stack exist, if not and requested, then trigger the create of it
    begin
      cfn = Aws::CloudFormation::Client.new
      stack = cfn.describe_stacks(stack_name: $cfn_stack_name,)
    rescue => e
      if e.message.match(/Stack with id .* does not exist/)
        stack = nil 
      else
        puts "ERROR - failed to get a list of stacks, error was:"
        puts e
      end
    end

    if $cfn_create_if_not_exist && stack.nil?
      puts "WARN - Environment does not exist, creating"
      Rake::Task["cfn:create"].invoke 
      exit 0
    end

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

