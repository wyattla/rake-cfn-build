namespace :cfn do

  desc 'Get Cloudformation events'
  task :get_ansible_status => :init do |t|

    ######################################################################
    # Environment variables / task parameters

    project_name = ENV['EV_PROJECT_NAME'] || fail('error: EV_PROJECT_NAME not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('error: no EV_ENVIRONMENT not defined')

    build_number = ENV['EV_BUILD_NUMBER'] || fail('error: no EV_BUILD_NUMBER not defined') 

    timeout = 300 || ENV['EV_TIMEOUT']

    ######################################################################
    # Do the stuff

    # Open an aws connection
    ec2 = Aws::EC2::Client.new(region: 'eu-west-1')

    # Filter the instances for this environment and project name
    filter = [ 
      { name: "tag:Environment", values: [environment] },
      { name: "tag:ProjectName", values: [project_name] },
      { name: "instance-state-name", values: ["running"] } 
    ]

    instances_pending_to_build = nil
    ansible_run_tags = nil
    instances = nil
    error_status = 0

    loop do 

      # Calculate how many instances didn't run ansible yet
      reservations = ec2.describe_instances(filters: filter).reservations
      instances = reservations.map(&:instances).flatten
      tags = instances.map(&:tags).flatten
      ansible_run_tags = tags.map { |tag| tag.value if tag.key == "AnsibleRun"}.compact
      instances_build_status = ansible_run_tags.map { |tag| tag.scan(/build=\d+/) }.flatten
      instances_pending_to_build = instances_build_status.select { |x| x != "build=#{build_number}" }

      # Break if we reached the time out or if all the instances are on the latest build number
      break if timeout == 0 || instances_pending_to_build.empty?

      # Decrease timeout
      timeout -= 1
      sleep 1

    end

    failed_status = ansible_run_tags.map { |tag| tag.scan(/failed=\d+/) }.sort.uniq.size == 1

    unless instances_pending_to_build.empty?
      puts "ERROR: One or more instances didn't run the latest ansible build"
      error_status = 1
    end

    unless failed_status
      puts "ERROR: One or more instances failed to apply ansible"
      error_status = 1
    end

    report = []
    instances.each do |i|
      instance_id = i.instance_id
      instance_name = i.tags.map { |tag| tag.value if tag.key == "Name" }.compact.first
      ansible_result = i.tags.map { |tag| tag.value if tag.key == "AnsibleRun" }.compact.first
      report << "#{instance_id} (#{instance_name}) - #{ansible_result}"
    end

    puts "\n\nAnsible run report:"
    puts "===================\n"
    puts report

    exit error_status

  end

end
