namespace :cfn do

  desc 'Debug with ruby-dsl'
  task :debug => :init do

    cfn = Aws::CloudFormation::Client.new
    binding.pry

  end

end
