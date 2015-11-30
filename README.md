# rake-cfn-build

A set of rake tasks for building a VPC and the resources defined within it.

## Requirements

- ruby 2.2.x (where x is the latest stable version of ruby)
- bundler

There are additional requirements defined in `Gemfile` which are installed by  bundler.

## Setup

**Note**: Only tested on \*NIX so no assurance this will run
on Windows. Moreover, rvm which is used for development and deployment
is not natively available on Windows (cygwin is required).

### Dependencies

1. Install the Ruby Version Manager (rvm) https://rvm.io/rvm/install
1. Install the current stable version of ruby 2.2.x
  ```
  rvm install 2.2.3
  ```
1. Install bundler into the global gemset
  ```
  rvm use 2.2.3@global
  gem install bundler
  rvm gemset clear
  ```
1. Clone this repository.
1. Change directory to where the repo was cloned.
1. Install the required libraries using bundler.
   ```
   bundle install
   ```


## Required configuration

### Prerequisites
The S3 bucket that is specified in the `EV_BUCKET_NAME` environment
variable (see below) __MUST__ be created ahead of time. It will __NOT__
be created when the tests are run. 

### Project specific variables

The following environment variables __MUST__ be defined for things to
work. The best way to test if things are defined is to run `cucumber`
in the current directory. There will be output to inform you if
required environment variables aren't present.

Test project specific variables

```
export EV_BUCKET_NAME=< name of your S3 bucket >
export EV_PROJECT_NAME=testproj
export EV_ENVIRONMENT=test
export EV_GIT_PATH=resources/test_app
export EV_CREATE_IF_NOT_EXIST=true
export EV_BUILD_NUMBER=93
```

of the above `EV_GIT_PATH` is a relative path to the git repository
that contains the application for which the infrastructure will be
built. This is normally a separate git repository.

### AWS credentials

```
export AWS_ACCESS_KEY_ID=< for your AWS IAM user >
export AWS_SECRET_ACCESS_KEY=< for your AWS IAM user >
export AWS_DEFAULT_REGION=eu-west-1
```

Now you should run `cucumber` which will build and tear down a test
environment. During initial setup, it is likely useful to have the AWS
console open in a web browser since some created entities may not be
removed if the cucumber tests have errors during their run.

### Naming conventions

S3 bucket names must be globally unique and not account specific. It
is important that the bucket name provide context for the product,
environment and component. See http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
for further information in what is allowed in an S3 bucket name.

The current suggested naming convention is:

```
els-<product name>-<environment>-<component>
```

e.g.

```
els-rds-nonprod-infrastructurebuild
```
