namespace :cfn do
  desc 'Upload templates to s3'
  task upload: :init do

    ######################################################################
    # Environment variables / task parameters

    bucket_name = ENV['EV_BUCKET_NAME'] || fail('ERROR: EV_BUCKET_NAME not defined')

    project_name = ENV['EV_PROJECT_NAME'] || fail('ERROR: EV_PROJECT_NAME not defined')

    environment = ENV['EV_ENVIRONMENT'] || fail('ERROR: no EV_ENVIRONMENT not defined')

    git_path = ENV['EV_GIT_PATH'] || fail('ERROR: no EV_GIT_PATH not defined')

    ######################################################################
    # Variables definitions and validations

    rubycfndsl_path = File.join(git_path, 'rubycfndsl')
    rubycfndsl_files = Dir.glob(File.join(rubycfndsl_path, '*rb')).map do |x|
      File.expand_path x
    end

    fail "ERROR: No templates found on #{rubycfndsl_path}" if rubycfndsl_files.empty?

    ansible_path = File.join(git_path, 'ansible')
    ansible_playbooks_raw = Dir.glob(File.join(ansible_path, 'playbooks', '*yml'))
    ansible_playbooks = ansible_playbooks_raw.map do |x|
      File.expand_path x unless x.match(/common/)
    end.compact

    s3 = Aws::S3::Resource.new

    ######################################################################
    # Upload all the cloud formation templates to the s3 bucket

    begin

      rubycfndsl_files.each do |file|

        # Variables:
        file_name = file.split('/').last
        template_cfn_name = file_name.split('.').first + '.template'
        template_key = File.join(project_name, environment, 'cloudformation',
                                 template_cfn_name)

        # Generate json template:
        cmd = "bundle exec #{file} expand > tmp/#{template_cfn_name}"
        pid, _stdin, _stdout, stderr = Open4.popen4 cmd
        _ignored, status = Process.waitpid2 pid
        if status.exitstatus != 0
          fail "Error creating json template on #{file} \n#{stderr.read}"
        end

        # Upload json template to s3
        obj = s3.bucket(bucket_name).object(template_key)
        obj.upload_file(File.join('tmp', template_cfn_name))

      end

      s3_cfn_location = File.join(bucket_name, project_name, environment, 'cloudformation')
      puts "INFO: Cloud formation templates uploaded to s3://#{s3_cfn_location}"

    rescue => e
      puts "ERROR: failed to upload templates to s3://#{s3_cfn_location}, error was:"
      puts e
      exit 1
    end

    ######################################################################
    # Create application roles and upload ansible playbooks to s3 bucket

    begin

      ansible_playbooks.each do |playbook|

        # Some variable definitions
        role = File.basename(playbook).split('.').first
        tarfile = "ansible-playbook-#{role}.tar.gz"
        files = ['ansible.cfg', 'playbooks/shared_vars', 'playbooks/common.yml',
                 "playbooks/#{role}.yml", 'roles', "environments/#{environment}/inventory",
                 "environments/#{environment}/group_vars/#{role}",
                 "environments/#{environment}/host_vars"]

        # Remove paths that doen't exist
        files.map! { |f| f if File.exist? File.join(ansible_path, f) }.compact

        # Create the taarball file
        cmd = "cd #{ansible_path} && tar zcf #{tarfile} #{files.join(' ')}"
        pid, _stdin, _stdout, stderr = Open4.popen4 cmd
        _ignored, status = Process.waitpid2 pid
        if status.exitstatus != 0
          fail "ERROR: Failed to create tar file #{tarfile} \n#{stderr.read}"
        end

        # Upload tarfile to s3
        tarfile_key = File.join(project_name, environment, 'ansible', tarfile)
        obj = s3.bucket(bucket_name).object(tarfile_key)
        obj.upload_file(File.join(ansible_path, tarfile))

        # Upload the version file to s3
        git_hash = Random.new_seed.to_s
        version_key = File.join(project_name, environment, 'ansible', 'version')
        obj = s3.bucket(bucket_name).object(version_key)
        obj.put(body: git_hash)

        # Clean up
        FileUtils.rm File.join(ansible_path, tarfile)

      end

      s3_ansible_location = File.join(bucket_name, project_name, environment, 'ansible')
      puts "INFO: Ansible playbooks uploaded to s3://#{s3_ansible_location}"

    rescue => e
      puts 'ERROR: failed to upload ansible tarfile to s3, error was:'
      puts e
      exit 1
    end

  end

end
