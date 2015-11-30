namespace :cfn do

  desc 'Delete a stack using the AWS API'
  task :delete_stack => :init do

    ######################################################################
    # Environment variables / task parameters

    project_name = ENV['EV_PROJECT_NAME'] || fail('error: EV_PROJECT_NAME not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')

    cfn_stack_name = ENV['EV_CFN_STACK_NAME'] || "#{project_name}-#{environment}" 

    ######################################################################
    # Variables definitions and validations

    begin

      # Delete the stack
      cfn = Aws::CloudFormation::Client.new
      cfn.delete_stack(stack_name: cfn_stack_name)
      puts "INFO: Template delete triggered for #{cfn_stack_name}\n\n"

      # Invoke cfn:get_cfn_events to monitor the logs
      Rake::Task["cfn:get_cfn_events"].invoke

    rescue => e
      puts 'ERROR: failed to delete the stack, error was:'
      puts e
      exit 1
    end

  end

end
