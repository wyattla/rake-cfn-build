namespace :cfn do

  desc 'Validate all the templates'
  task :validate => :init do

    ######################################################################
    # Environment variables / task parameters

    application_path = ENV['EV_GIT_PATH'] || fail('error: no EV_GIT_PATH not defined')

    ######################################################################
    # Variables definitions and validations

    rubycfndsl_path = File.join(application_path, 'rubycfndsl')
    rubycfndsl_files = Dir.glob(File.join(rubycfndsl_path, '*rb')).map do |x|
      File.expand_path x
    end

    fail "ERROR: No templates found on #{rubycfndsl_path}" if rubycfndsl_files.empty?

    ######################################################################
    # Validate the templates

    begin

      puts "INFO: Validating cfn templates \n\n"
      rubycfndsl_files.each do |file|

        # Validate the stack
        cmd = "bundle exec #{file} validate"
        pid, _stdin, stdout, stderr = Open4.popen4 cmd
        _ignored, status = Process.waitpid2 pid

        # Exit if command failed
        fail "Error executing #{cmd}:\n #{stderr.read}" if status.exitstatus != 0

        # Return status:
        puts "#{File.basename(file)} #{stdout.read}"
      end

    rescue => e
      puts 'ERROR: failed to create template, error was:'
      puts e
      exit 1
    end

  end

end
