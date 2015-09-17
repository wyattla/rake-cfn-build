namespace :cfn do

  desc "List all the CFN stacks"
  task :list do

    begin

      # Select only the stacks that contain the pattern MAIN VPC at the beginning
      cfn = Aws::CloudFormation::Client.new
      stacks = cfn.describe_stacks.stacks.select do |x| 
        x.description.match(/^MAIN VPC/) if not x.description.nil? 
      end

      # Print the staccck name
      puts stacks.map { |x| x.stack_name}

    rescue => e
      puts "ERROR - failed to list the cloud formation stacks template, error was:"
      puts e
      exit 1
    end

  end

end

