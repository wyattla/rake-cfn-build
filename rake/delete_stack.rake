namespace :cfn do

  desc 'Delete a stack using the AWS API'
  task :delete_stack => :init do

    # Mandatory variables
    cfn_stack_name = ENV['EV_CFN_STACK_NAME']

    # Get the stack, and delete it
    begin
      cfn = Aws::CloudFormation::Client.new
      cfn.delete_stack(stack_name: cfn_stack_name)
      puts "INFO: Template delete triggered for #{cfn_stack_name}"
    rescue => e
      puts 'ERROR: failed to delete the stack, error was:'
      puts e
      exit 1
    end

  end

end
