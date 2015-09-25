namespace :cfn do

  desc "Delete a stack using cloud formation template"
  task :delete => :init do

    # Env variables definition:
    $bucket_name = ENV['EV_BUCKET_NAME'] || raise('error: EV_BUCKET_NAME not defined')
    $application_name = ENV['EV_APPLICATION_NAME'] || raise('error: EV_APPLICATION_NAME not defined')
    $project_name = ENV['EV_PROJECT_NAME'] || raise('error: EV_PROJECT_NAME not defined')
    $environment = ENV['EV_ENVIRONMENT'] || raise('error: no EV_ENVIRONMENT not defined')
    $application_path = ENV['EV_GIT_PATH'] || raise('error: no EV_GIT_PATH not defined')
    $cfn_create_if_not_exist = ENV['EV_CREATE_IF_NOT_EXIST'].nil? ? false : ENV['EV_CREATE_IF_NOT_EXIST']

    # Variables
    $cfn_templates = Dir.glob(File.join('cloudformation',$application_path,'*rb')).map {|x| File.expand_path x }
    $stack_name = $project_name + '-' + $application_name
    $cfn_stack_name = $environment + '-' + $stack_name

    # Execute the main template
    begin

      # Delete stack
      cmd = "bundle exec #{File.join($cfn_templates,'main.rb')} delete #{$cfn_stack_name}"
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

