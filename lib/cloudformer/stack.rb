class Stack
  attr_accessor :stack, :name, :deployed
  def initialize(stack_name)
    @name = stack_name
    @cf = AWS::CloudFormation.new
    @stack = @cf.stacks[name]
  end

  def deployed
    return stack.exists?
  end

  def apply(template_file, parameters)
    template = File.read(template_file)
    validation = validate(template)
    unless validation["valid"]
      puts "Unable to update - #{validation["response"][:code]} - #{validation["response"][:message]}"
      return 1
    end
    pending_operations = false
    if deployed
      pending_operations = update(template, parameters)
    else
      pending_operations = create(template, parameters)
    end
    wait_until_end if pending_operations
    if stack.status == "ROLLBACK_COMPLETE"
      puts "Unable to update template. Check log for more information."
      return 1
    else
      return 0
    end
  end

  def delete
    with_highlight do
      puts "Attempting to delete stack - #{name}"
      stack.delete
      wait_until_end
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
        puts "#{event.timestamp} - #{event.resource_type} - #{event.resource_status} - #{event.resource_status_reason.to_s}"
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

  private
  def wait_until_end
    printed = []
    with_highlight do
      if !deployed
        puts "Stack not up."
        return
      end
      loop do
        exit_loop = false
        printable_events = stack.events.sort_by {|a| a.timestamp}.reject {|a| a if printed.include?(a.event_id)}
        printable_events.each do |event|
          puts "#{event.timestamp} - #{event.resource_type} - #{event.resource_status} - #{event.resource_status_reason.to_s}"
          if event.resource_type == "AWS::CloudFormation::Stack" && !event.resource_status.match(/_COMPLETE$/).nil?
            exit_loop = true
          end
        end
        printed.concat(printable_events.map(&:event_id))
        break if !stack.status.match(/_COMPLETE$/).nil?
        sleep(5)
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

  def update(template, parameters)
    stack.update({
      :template => template,
      :parameters => parameters
    })
    return true
  rescue ::AWS::CloudFormation::Errors::ValidationError => e
    puts e.message
    return false
  end

  def create(template, parameters)
    puts "Initializing stack creation..."
    @cf.stacks.create(name, template, :parameters => parameters)
    sleep 10
    return true
  rescue ::AWS::CloudFormation::Errors::ValidationError => e
    puts e.message
    return false
  end
end
