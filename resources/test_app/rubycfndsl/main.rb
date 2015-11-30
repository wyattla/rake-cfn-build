#!/usr/bin/env ruby

# Standard cfn-ruby libraries:
require 'pry'
require 'bundler/setup'
require 'cloudformation-ruby-dsl/cfntemplate'
require 'cloudformation-ruby-dsl/spotprice'
require 'cloudformation-ruby-dsl/table'

# Set environment
$environment = ENV['EV_ENVIRONMENT'] || raise('error: no EV_ENVIRONMENT provided')
$application = ENV['EV_APPLICATION'] || raise('error: no EV_APPLICATION provided')
$bucketname = ENV['EV_BUCKET_NAME'] || raise('error: no EV_BUCKET_NAME provided')

template do

  # Format Version:
  
  value :AWSTemplateFormatVersion => '2010-09-09'

  # Description:
  
  value :Description => "MAIN VPC Configuration for #{$application.upcase}"

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

  parameter 'ApplicationName',
    :Default => $application,
    :Description => 'The Application Name',
    :Type => 'String',
    :MinLength => '1',
    :MaxLength => '64',
    :AllowedPattern => '[a-zA-Z][a-zA-Z0-9]*',
    :ConstraintDescription => 'must begin with a letter and contain only alphanumeric characters.'

  parameter 'CfnBucketName',
    :Default => $bucketname,
    :Description => 'The Application Name',
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
        { :Key => 'Name', :Value => join('-',ref('ApplicationName'),ref('EnvironmentName'),'ec2',ref('AnsibleRole')) }, 
        { :Key => 'Environment', :Value => ref('EnvironmentName') },
        { :Key => 'AnsibleRole', :Value => ref('AnsibleRole')},                                                     
        { :Key => 'ApplicationName', :Value => ref('ApplicationName') },                                                    
        { :Key => 'AnsibleRun', :Value => 'build=93 ok=23 changed=5 unreachable=1 failed=0' },                                                    
      ],
    }

end.exec!
