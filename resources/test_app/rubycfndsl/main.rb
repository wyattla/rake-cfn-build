#!/usr/bin/env ruby

# Standard cfn-ruby libraries:
require 'pry'
require 'bundler/setup'
require 'cloudformation-ruby-dsl/cfntemplate'
require 'cloudformation-ruby-dsl/spotprice'
require 'cloudformation-ruby-dsl/table'

# Set environment
$environment = ENV['EV_ENVIRONMENT'] || raise('error: no EV_ENVIRONMENT provided')
$projectname = ENV['EV_PROJECT_NAME'] || raise('error: no EV_PROJECT_NAME provided')
$bucketname = ENV['EV_BUCKET_NAME'] || raise('error: no EV_BUCKET_NAME provided')

template do

  # Format Version:
  
  value :AWSTemplateFormatVersion => '2010-09-09'

  # Description:
  
  value :Description => "MAIN VPC Configuration for #{$projectname.upcase}"

  ####################################################################################################
  ####################################################################################################
  #
  # Parameters
  #
  ####################################################################################################
  ####################################################################################################
  
  # Default Mandatory Parameters

  parameter 'EnvironmentName',
    :Default => $environment,
    :Description => 'The environment Name',
    :Type => 'String',
    :MinLength => '1',
    :MaxLength => '64',
    :AllowedPattern => '[a-zA-Z][a-zA-Z0-9]*',
    :ConstraintDescription => 'must begin with a letter and contain only alphanumeric characters.'

  parameter 'ProjectName',
    :Default => $projectname,
    :Description => 'The Project Name',
    :Type => 'String',
    :MinLength => '1',
    :MaxLength => '64',
    :AllowedPattern => '[a-zA-Z][a-zA-Z0-9]*',
    :ConstraintDescription => 'must begin with a letter and contain only alphanumeric characters.'

  parameter 'CfnBucketName',
    :Default => $bucketname,
    :Description => 'The Project Name',
    :Type => 'String',
    :MinLength => '1',
    :MaxLength => '64',
    :AllowedPattern => '[a-zA-Z0-9-\.]*',
    :ConstraintDescription => 'must begin with a letter and contain only alphanumeric characters.'

  parameter 'AnsibleRole',
    :Default => 'test',
    :Type => 'String'

  ####################################################################################################
  ####################################################################################################
  #
  # Mappings including Subnets
  #
  ####################################################################################################
  ####################################################################################################
 
  Dir[File.join(File.expand_path(File.dirname($0)),'maps','*')].each do |map|
    eval File.read(map)
  end

  ####################################################################################################
  ####################################################################################################
  #
  # VPC Resources
  #
  ####################################################################################################
  ####################################################################################################

  resource :EC2Instance,
    :Type => "AWS::EC2::Instance",
    :Properties => {
      :InstanceType => 'm3.medium',
      :ImageId => 'ami-4ac6653d',
      :SourceDestCheck => 'false',
      :Tags => [ 
        { :Key => 'Name', :Value => join('-',ref('ProjectName'),ref('EnvironmentName'),'ec2',ref('AnsibleRole')) }, 
        { :Key => 'Environment', :Value => ref('EnvironmentName') },
        { :Key => 'AnsibleRole', :Value => ref('AnsibleRole')},                                                     
        { :Key => 'ProjectName', :Value => ref('ProjectName') },                                                    
        { :Key => 'AnsibleRun', :Value => 'build=93 ok=23 changed=5 unreachable=1 failed=0' },                                                    
      ],
    }

end.exec!
