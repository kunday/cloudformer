![Build Status](https://travis-ci.org/kunday/cloudformer.svg?branch=master)

# CloudFormer

Cloudformer attempts to simplify AWS Cloudformation stack creation process in ruby projects by providing reusable rake tasks to perform common operations such as apply(create/update), delete, recreate on stack along with validations on templates. Task executions which enforce a stack change will wait until ROLLBACK/COMPLETE or DELETE is signalled on the stack (useful in continuous deployment environments to wait until deployment is successful). Refer [examples section](#example) for more information.

### Note:
This gem requires aws-sdk version 1.0 series, 2.0 series has some problems which is holding the upgrade to ruby 2.0.

The list of rake tasks provided are:

```

rake apply           # Apply Stack with Cloudformation script and parameters(And wait till complete - supports updates)
rake delete          # Delete stack from CloudFormation(And wait till stack is complete)
rake events          # Get the recent events from the stack
rake outputs         # Get the outputs of stack
rake recreate        # Recreate stack(runs delete & apply)
rake status          # Get the deployed app status

```


## Installation

Add this line to your application's Gemfile:

    gem 'cloudformer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloudformer

## AWS Environment configuration

Cloudformer depends on the aws-sdk gem to query AWS API. You will need to export AWS configuration to environment variables to your .bashrc/.bash_profile or your build server:

    export AWS_ACCESS_KEY=your access key
    export AWS_REGION=ap-southeast-2
    export AWS_SECRET_ACCESS_KEY=your secret access key


## Configuration

You can add cloudformer tasks to your project by adding the following to your rake file:

	require 'cloudformer'
    Cloudformer::Tasks.new("earmark") do |t|
      t.template = "cloudformation/cloudformation.json"
      t.parameters = parameters
    end

where `cloudformation/cloudformation.json` is the stack json file and parameters is a hash of parameters used in the template.
For a template which takes the following parameters:

    "Parameters": {
      "PackageUrl": {
        "Type": "String"
      },
      "PackageVersion": {
        "Type": "String"
      }
    }

the parameter hash(Ruby Object) would look like:

    {
      "PackageUrl" => "http://localhost/app.rpm",
      "PackageVersion" => "123"
    }

If you have a template with no parameters, pass an empty hash `{}` instead.

## Example

Here is a simple Cloudformation Stack(Code available in the samples directory) with a Single EC2 Server:

    {
      "AWSTemplateFormatVersion": "2010-09-09",
      "Description": "Cloudformer - Demo App",
      "Parameters": {
        "AmiId": {
          "Type": "String"
        }
        },
        "Resources": {
          "ApplicationServer": {
            "Type": "AWS::EC2::Instance",
            "Properties": {
              "ImageId": {
                "Ref": "AmiId"
                },
                "InstanceType": "t1.micro",
                "Monitoring": "false"
            }
          }
        },
        "Outputs": {
          "Server": {
            "Value": {
              "Fn::GetAtt": [
                "ApplicationServer",
                "PrivateIp"
              ]
            }
          }
        }
    }

Then, in your Rakefile add,

    require 'cloudformer/tasks'

    Cloudformer::Tasks.new("app") do |t|
      t.template = "basic_template.json"
      t.tags = [{'Key' => 'Name',  'Value' => 'BASIC-TMPLT'},
                {'Key' => 'Owner', 'Value' => 'APPOWNER'}]

      #AMI Works in Sydney region only, ensure you supply the right AMI.
      t.parameters = {"AmiId" => "ami-8da439b7"}
    end

You should then see following commands:

    rake apply     # Apply Stack with Cloudformation script and parameters
    rake delete    # Delete stack from CloudFormation
    rake events    # Get the recent events from the stack
    rake outputs   # Get the outputs of stack
    rake recreate  # Recreate stack
    rake status    # Get the deployed app status

Running `rake status` gives us:

    ===============================================
      app - Not Deployed
    ================================================

Running `rake apply` will create an environment or update existing depending on the nature of action requested in parameters:

    Initializing stack creation...
    ==================================================================================================
    2013-10-24 07:55:24 UTC - AWS::CloudFormation::Stack - CREATE_IN_PROGRESS - User Initiated
    2013-10-24 07:55:36 UTC - AWS::EC2::Instance - CREATE_IN_PROGRESS -
    2013-10-24 07:55:37 UTC - AWS::EC2::Instance - CREATE_IN_PROGRESS - Resource creation Initiated
    2013-10-24 07:56:25 UTC - AWS::EC2::Instance - CREATE_COMPLETE -
    2013-10-24 07:56:26 UTC - AWS::CloudFormation::Stack - CREATE_COMPLETE -
    ==================================================================================================

Running `rake apply` again gives us:

    No updates are to be performed.

To remove the stack `rake delete` gives us:

    ==============================================================================================
    Attempting to delete stack - app
    ==============================================================================================
    2013-10-24 07:55:24 UTC - AWS::CloudFormation::Stack - CREATE_IN_PROGRESS - User Initiated
    2013-10-24 07:55:36 UTC - AWS::EC2::Instance - CREATE_IN_PROGRESS -
    2013-10-24 07:55:37 UTC - AWS::EC2::Instance - CREATE_IN_PROGRESS - Resource creation Initiated
    2013-10-24 07:56:25 UTC - AWS::EC2::Instance - CREATE_COMPLETE -
    2013-10-24 07:56:26 UTC - AWS::CloudFormation::Stack - CREATE_COMPLETE -
    2013-10-24 07:58:54 UTC - AWS::CloudFormation::Stack - DELETE_IN_PROGRESS - User Initiated
    2013-10-24 07:58:56 UTC - AWS::EC2::Instance - DELETE_IN_PROGRESS -

Attempts to delete a non-existing stack will result in:

    ==============================================
    Attempting to delete stack - app
    ==============================================
    Stack not up.
    ==============================================

To recreate the stack use `rake recreate`:

    =================================================================================================
    Attempting to delete stack - app
    =================================================================================================
    2013-10-24 08:04:11 UTC - AWS::CloudFormation::Stack - CREATE_IN_PROGRESS - User Initiated
    2013-10-24 08:04:22 UTC - AWS::EC2::Instance - CREATE_IN_PROGRESS -
    2013-10-24 08:04:23 UTC - AWS::EC2::Instance - CREATE_IN_PROGRESS - Resource creation Initiated
    2013-10-24 08:05:12 UTC - AWS::EC2::Instance - CREATE_COMPLETE -
    2013-10-24 08:05:13 UTC - AWS::CloudFormation::Stack - CREATE_COMPLETE -
    2013-10-24 08:05:52 UTC - AWS::CloudFormation::Stack - DELETE_IN_PROGRESS - User Initiated
    2013-10-24 08:06:02 UTC - AWS::EC2::Instance - DELETE_IN_PROGRESS -
    Stack deleted successfully.
    Initializing stack creation...
    =================================================================================================
    2013-10-24 08:06:31 UTC - AWS::CloudFormation::Stack - CREATE_IN_PROGRESS - User Initiated
    2013-10-24 08:06:52 UTC - AWS::EC2::Instance - CREATE_IN_PROGRESS -
    2013-10-24 08:06:54 UTC - AWS::EC2::Instance - CREATE_IN_PROGRESS - Resource creation Initiated
    2013-10-24 08:07:41 UTC - AWS::EC2::Instance - CREATE_COMPLETE -
    =================================================================================================
    =================================================================================================
    Server -  - 172.31.3.52
    =================================================================================================

To see the stack outputs `rake outputs`:

    ==============================
    Server -  - 172.31.3.52
    ==============================

To see recent events on the stack `rake events`:

    ==================================================================================================
    2013-10-24 08:06:31 UTC - AWS::CloudFormation::Stack - CREATE_IN_PROGRESS - User Initiated
    2013-10-24 08:06:52 UTC - AWS::EC2::Instance - CREATE_IN_PROGRESS -
    2013-10-24 08:06:54 UTC - AWS::EC2::Instance - CREATE_IN_PROGRESS - Resource creation Initiated
    2013-10-24 08:07:41 UTC - AWS::EC2::Instance - CREATE_COMPLETE -
    2013-10-24 08:07:43 UTC - AWS::CloudFormation::Stack - CREATE_COMPLETE -
    ==================================================================================================

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
