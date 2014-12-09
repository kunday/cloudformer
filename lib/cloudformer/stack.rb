require 'aws-sdk'
require 'httparty'

class Stack
  attr_accessor :stack, :name, :deployed

  SUCESS_STATES  = ["CREATE_COMPLETE", "UPDATE_COMPLETE"]
  FAILURE_STATES = ["CREATE_FAILED", "DELETE_FAILED", "UPDATE_ROLLBACK_FAILED", "ROLLBACK_FAILED", "ROLLBACK_COMPLETE","ROLLBACK_FAILED","UPDATE_ROLLBACK_COMPLETE","UPDATE_ROLLBACK_FAILED"]
  END_STATES     = SUCESS_STATES + FAILURE_STATES

  # WAITING_STATES = ["CREATE_IN_PROGRESS","DELETE_IN_PROGRESS","ROLLBACK_IN_PROGRESS","UPDATE_COMPLETE_CLEANUP_IN_PROGRESS","UPDATE_IN_PROGRESS","UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS","UPDATE_ROLLBACK_IN_PROGRESS"]
  def initialize(stack_name)
    @name = stack_name
    @cf = AWS::CloudFormation.new
    @stack = @cf.stacks[name]
    @ec2 = AWS::EC2.new
  end

  def deployed
    return stack.exists?
  end

  def apply(template_file, parameters, disable_rollback=false, capabilities=[], notify=[], tags=[])
    if ( template_file =~ /^https:\/\/s3\S+\.amazonaws\.com\/(.*)/ )
      template = template_file
    elsif ( template_file =~ /^http.*(.json)$/ )
      begin
        response = HTTParty.get(template_file)
        template = response.body
      rescue => e
        puts "Unable to retieve json file for template from #{template_file} - #{e.class}, #{e}"
        return :Failed
      end
    else
      template = File.read(template_file)
    end
    validation = validate(template)
    unless validation["valid"]
      puts "Unable to update - #{validation["response"][:code]} - #{validation["response"][:message]}"
      return :Failed
    end
    pending_operations = false
    begin
      if deployed
        pending_operations = update(template, parameters, capabilities)
      else
        pending_operations = create(template, parameters, disable_rollback, capabilities, notify, tags)
      end
    rescue ::AWS::CloudFormation::Errors::ValidationError => e
      puts e.message
      return (if e.message == "No updates are to be performed." then :NoUpdates else :Failed end)
    end
    wait_until_end if pending_operations
    return (if deploy_succeded? then :Succeeded else :Failed end)
  end

  def deploy_succeded?
    return true unless FAILURE_STATES.include?(stack.status)
    puts "Unable to deploy template. Check log for more information."
    false
  end

  def stop_instances
   update_instances("stop")
  end

  def start_instances
    update_instances("start")
  end

  def delete
    with_highlight do
      puts "Attempting to delete stack - #{name}"
      stack.delete
      wait_until_end
      return deploy_succeded?
    end
  end

  def status
    with_highlight do
      if deployed
        puts "#{stack.name} - #{stack.status} - #{stack.status_reason}"
      else
        puts "#{name} - Not Deployed"
      end
    end
  end

  def events(options = {})
    with_highlight do
      if !deployed
        puts "Stack not up."
        return
      end
      stack.events.sort_by {|a| a.timestamp}.each do |event|
        puts "#{event.timestamp} - #{event.physical_resource_id.to_s} - #{event.logical_resource_id} - #{event.resource_type} - #{event.resource_status} - #{event.resource_status_reason.to_s}"
      end
    end
  end

  def outputs
    with_highlight do
    if !deployed
      puts "Stack not up."
      return 1
    end
      stack.outputs.each do |output|
        puts "#{output.key} - #{output.description} - #{output.value}"
      end
    end
    return 0
  end

  def validate(template)
    response = @cf.validate_template(template)
    return {
      "valid" => response[:code].nil?,
      "response" => response
    }
  end

  private
  def wait_until_end
    printed = []
    current_time = Time.now
    with_highlight do
      if !deployed
        puts "Stack not up."
        return
      end
      loop do
        printable_events = stack.events.reject{|a| (a.timestamp < current_time)}.sort_by {|a| a.timestamp}.reject {|a| a if printed.include?(a.event_id)}
        printable_events.each { |event| puts "#{event.timestamp} - #{event.physical_resource_id.to_s} - #{event.resource_type} - #{event.resource_status} - #{event.resource_status_reason.to_s}" }
        printed.concat(printable_events.map(&:event_id))
        break if END_STATES.include?(stack.status)
        sleep(30)
      end
    end
  end

  def with_highlight &block
    cols = `tput cols`.chomp!.to_i
    puts "="*cols
    yield
    puts "="*cols
  end

  def validate(template)
    response = @cf.validate_template(template)
    return {
      "valid" => response[:code].nil?,
      "response" => response
    }
  end

  def update(template, parameters, capabilities)
    stack.update({
      :template => template,
      :parameters => parameters,
      :capabilities => capabilities
    })
    return true
  end

  def create(template, parameters, disable_rollback, capabilities, notify, tags)
    puts "Initializing stack creation..."
    @cf.stacks.create(name, template, :parameters => parameters, :disable_rollback => disable_rollback, :capabilities => capabilities, :notify => notify, :tags => tags)
    sleep 10
    return true
  end

  def update_instances(action)
    with_highlight do
      puts "Attempting to #{action} all ec2 instances in the stack #{stack.name}"
      return "Stack not up" if !deployed
      stack.resources.each do |resource|
        begin
          next if resource.resource_type != "AWS::EC2::Instance"
          physical_resource_id = resource.physical_resource_id
          puts "Attempting to #{action} Instance with physical_resource_id: #{physical_resource_id}"
          @ec2.instances[physical_resource_id].send(action)
        rescue
          puts "Some resources are not up."
        end
      end
    end
  end
end

