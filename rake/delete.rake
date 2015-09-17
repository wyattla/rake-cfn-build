namespace :cfn do

  desc "Create a new environment using cloud formation"
  task :delete => :init do

    # Mandatory variables
    $cfn_path = ENV['CFN_TEMPLATE_PATH'] || raise('error: no CFN_TEMPLATE_PATH not defined')
    $cfn_stack_name = ENV['CFN_STACK_NAME']

    # Build cfn_stack_name if not defined through CFN_STACK_NAME
    if $cfn_stack_name.nil?
      # Env variables definition:
      $bucket_name = ENV['CFN_BUCKETNAME'] || raise('error: CFN_BUCKETNAME not defined')
      $application_name = ENV['CFN_APPLICATIONNAME'] || raise('error: CFN_APPLICATIONNAME not defined')
      $project_name = ENV['CFN_PROJECTNAME'] || raise('error: CFN_PROJECTNAME not defined')
      $environment = ENV['CFN_ENVIRONMENT'] || raise('error: no CFN_ENVIRONMENT not defined')

      # Variables
      $stack_name = $project_name + '-' + $application_name
      $cfn_stack_name = $environment + '-' + $stack_name
    end

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

