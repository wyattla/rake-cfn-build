namespace :cfn do

  desc "Validate"
  task :validate => :init do

    # Env variables definition:
    $application_path = ENV['EV_GIT_PATH'] || raise('error: no EV_GIT_PATH not defined')

    # Variables
    $rubycfndsl_files = Dir.glob(File.join($application_path,'cloudformation','*rb')).map {|x| File.expand_path x }
    
    # Execute the main template
    begin

      puts "INFO - Validating cfn templates
      "
      $rubycfndsl_files.each do |file|

        # Validate the stack
        cmd = "bundle exec #{file} validate"
        pid, stdin, stdout, stderr = Open4::popen4 cmd
        ignored, status = Process::waitpid2 pid

        # Exit if command failed
        raise "Error executing #{cmd}:\n #{stderr.read}" if status.exitstatus != 0

        # Return status:
        puts File.basename(file) + " " + stdout.read
      end

    rescue => e
      puts "ERROR - failed to create template, error was:"
      puts e
      exit 1
    end
    
  end

end

