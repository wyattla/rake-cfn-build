namespace :cfn do

  desc 'Create an environment using Cloud formation'
  task :describe_environment do

    ######################################################################
    # Environment variables / task parameters

    application = ENV['EV_APPLICATION'] || fail('error: EV_APPLICATION not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')

    cfn_stack_name = ENV['EV_CFN_STACK_NAME'] || "#{application}-#{environment}" 

    ######################################################################
    # Variables definitions and validations

    class Instance
      attr_accessor :name, :public_dns_name,:public_ip_address, :private_dns_name, :private_ip_address
    end

    ######################################################################
    # Connect to AWS and grab environment information

    begin

      ec2 = Aws::EC2::Client.new

      response = ec2.describe_instances({
        filters: [
          { name: "instance-state-name", values: ["running"], },
          { name: "tag:Application", values: [application], },
          { name: "tag:Environment", values: [environment], },
        ],
      })

      instances = response.reservations.map do |r|

        instance = r.instances.first
        instance_object = Instance.new

        name_tag = instance.tags.select {|t| t.key == "Name" }
        instance_object.name = name_tag.empty? ? "None" : name_tag.first.value
        instance_object.private_dns_name = instance.private_dns_name
        instance_object.private_ip_address = instance.private_ip_address
        instance_object.public_dns_name = instance.public_dns_name
        instance_object.public_ip_address = instance.public_ip_address

        instance_object

      end

      tp instances, :name, { private_dns_name:  {width: 60} }, :private_ip_address,
        { :public_dns_name => {width: 60} }, :public_ip_address

    rescue => e
      puts "ERROR: failed to grab #{cfn_stack_name} data, error was:"
      puts e
      exit 1
    end

  end

end
