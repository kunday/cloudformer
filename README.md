# Cloudformer

Cloudformer provides rake tasks to ease AWS Cloudformation stack creation process. Once configured, cloudformer provides the following set of tasks:

```

rake apply           # Apply Stack with Cloudformation script and parameters(And wait till complete)
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

Cloudformer depends on the aws-sdk gem to perform actions on AWS. You will need to export AWS configuration to your environment. You could export it to your .bashrc/.bash_profile or your build server using environment variables:

    export AWS_ACCESS_KEY=your access key
    export AWS_REGION=ap-southeast-2
    export AWS_SECRET_ACCESS_KEY=your secret access key


## Configuration

You can add cloudformer tasks to your project by adding something similar to:

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


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
