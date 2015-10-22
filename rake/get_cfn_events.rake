namespace :cfn do

  desc 'Get Cloudformation events'
  task :get_cfn_events => :init do |t|

    ######################################################################
    # Environment variables / task parameters

    project_name = ENV['EV_PROJECT_NAME'] || fail('error: EV_PROJECT_NAME not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')

    ######################################################################
    # Variables definitions and validations

    stack_events = []
    cfn_stack_name = "#{environment}-#{project_name}"
    cfn = Aws::CloudFormation::Client.new

    # Get a list of the stacks that match the environment name
    begin
      loop do

        # Exit the loop if there are no more stacks to querey (delete) or the stack is completed (create)
        cfn_stacks = cfn.describe_stacks.stacks.select { |s| s.stack_name.match(/#{cfn_stack_name}.*/) }
        break if cfn_stacks.empty?
        break if cfn.describe_stacks({stack_name: cfn_stack_name}).stacks.first.stack_status == 'CREATE_COMPLETE'

        cfn_stacks.each do |stack|
          sleep 0.1
          cfn.describe_stack_events({"stack_name" => stack.stack_name}).stack_events.reverse.each do |event|
            if stack_events.select{ |e| e.event_id == event.event_id }.empty?
              stack_events << event 
              if event.resource_status == 'CREATE_FAILED'
                printf "Resource: %-30.30s  Status: %-20.20s  LogicalId: %-30.30s\n".red, event.resource_type, event.resource_status, event.logical_resource_id
                puts "Reason: #{event.resource_status_reason}".red
              else
                printf "Resource: %-30.30s  Status: %-20.20s  LogicalId: %-30.30s\n", event.resource_type, event.resource_status, event.logical_resource_id
              end
            end
          end
        end
      end
    rescue => e
      puts e unless e.message.match(/Rate exceeded/)
      retry
    end

    puts
    t.reenable

  end

end
