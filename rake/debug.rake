namespace :cfn do

  desc 'Debug with ruby-dsl'
  task :debug => :init do

    ######################################################################
    # Environment variables / task parameters

    project_name = ENV['EV_PROJECT_NAME'] || fail('error: EV_PROJECT_NAME not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')

    ######################################################################
    # Variables definitions and validations

    stack_events = []
    cfn_stack_name = "#{project_name}-#{environment}"
    cfn = Aws::CloudFormation::Client.new

    # Get a list of the stacks that match the environment name
    begin
      loop do
        cfn.describe_stacks.stacks.select { |s| s.stack_name.match(/#{cfn_stack_name}.*/) }.each do |stack|
          sleep 1
          cfn.describe_stack_events({"stack_name" => stack.stack_name}).stack_events.each do |event|
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
    rescue
      retry
    end
      
      



  end

end
