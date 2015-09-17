namespace :cfn do

  desc "Validate"
  task :validate => :init do

    # Env variables definition:
    $cfn_path = ENV['CFN_TEMPLATE_PATH'] || raise('error: no CFN_TEMPLATE_PATH not defined')

    # Variables
    $cfn_templates = Dir.glob(File.join($cfn_path,'*rb')).map {|x| File.expand_path x }

    # Execute the main template
    begin

      puts "INFO - Validating cfn templates
      "
      $cfn_templates.each do |template|

        # Validate the stack
        cmd = "bundle exec #{template} validate"
        pid, stdin, stdout, stderr = Open4::popen4 cmd
        ignored, status = Process::waitpid2 pid

        # Exit if command failed
        raise "Error executing #{cmd}:\n #{stderr.read}" if status.exitstatus != 0

        # Return status:
        puts File.basename(template) + " " + stdout.read
      end

    rescue => e
      puts "ERROR - failed to create template, error was:"
      puts e
      exit 1
    end
    
  end

end

