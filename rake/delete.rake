namespace :cfn do

  desc "Create a new environment using cloud formation"
  task :delete => :init do

    # Execute the main template
    begin

      # Delete stack
      cmd = "bundle exec #{File.join($cfn_path,'main.rb')} delete #{$cfn_stack_name}"
      pid, stdin, stdout, stderr = Open4::popen4 cmd
      stdin.puts "y" 
      ignored, status = Process::waitpid2 pid

      # Exit if command failed
      raise "Error executing #{cmd}: #{stderr.read}" if status.exitstatus != 0
      puts "INFO - Template delete triggered for #{$cfn_stack_name}"

    rescue => e
      puts "ERROR - failed to delete template, error was:"
      puts e
      exit 1
    end
    
  end

end

