require 'cloudformer/version'
require 'cloudformer/stack'
require 'rake/tasklib'

module Cloudformer
  class Tasks < Rake::TaskLib
    def initialize(stack_name)
      @stack_name = stack_name
      @stack =Stack.new(stack_name)
      if block_given?
        yield self
        define_tasks
      end
    end

    attr_accessor :template, :parameters, :disable_rollback, :retry_delete, :capabilities, :notify, :tags
    attr_reader :stack_name

    private
    def define_tasks
      define_create_task
      define_validate_task
      define_delete_task
      define_delete_with_stop_task
      define_events_task
      define_status_task
      define_outputs_task
      define_recreate_task
      define_stop_task
      define_start_task
      define_list
    end

    def define_create_task
      desc "Apply Stack with Cloudformation script and parameters."
      task :apply, [:stack_name] do |t, args|
        if this_stack? args.stack_name
          if retry_delete
            @stack.delete
          end
          result = @stack.apply(template, parameters, disable_rollback, capabilities, notify, tags)
          if result == :Failed then exit 1 end
          if result == :NoUpdates then exit 0 end
        end
      end
    end

    def define_delete_task
      desc "Delete stack from CloudFormation"
      task :delete, [:stack_name] do |t, args|
        if this_stack? args.stack_name
          begin
            exit 1 unless @stack.delete
          rescue
            puts "#{stack_name} Stack deleted successfully."
          end
        end
      end
    end

    def define_delete_with_stop_task
      desc "Delete stack after stopping all instances"
      task :force_delete, [:stack_name] do |t, args|
        if this_stack? args.stack_name
          begin
            @stack.stop_instances
            exit 1 unless @stack.delete
          rescue => e
            puts "#{stack_name} Stack delete message - #{e.message}"
          end
        end
      end
    end

    def define_status_task
      desc "Get the deployed app status."
      task :status, [:stack_name] do |t, args|
        if this_stack? args.stack_name
          @stack.status
        end
      end
    end

    def define_events_task
      desc "Get the recent events from the stack."
      task :events, [:stack_name] do |t, args|
        if this_stack? args.stack_name
          @stack.events
        end
      end
    end

    def define_outputs_task
      desc "Get the outputs of stack."
      task :outputs, [:stack_name] do |t, args|
        if this_stack? args.stack_name
          @stack.outputs
        end
      end
    end

    def define_recreate_task
      desc "Recreate stack."
      task :recreate, [:stack_name] => [:delete, :apply, :outputs]
    end

    def define_stop_task
      desc "Stop EC2 instances in stack."
      task :stop, [:stack_name] do |t, args|
        if this_stack? args.stack_name
          @stack.stop_instances
        end
      end
    end

    def define_start_task
      desc "Start EC2 instances in stack."
      task :start, [:stack_name] do |t, args|
        if this_stack? args.stack_name
          @stack.start_instances
        end
      end
    end

    def define_validate_task
      desc "Validate the Stack."
      task :validate, [:stack_name] do |t, args|
        if this_stack? args.stack_name
          @stack.validate(template)
        end
      end
    end

    def define_list
      desc "List the names of the available stacks"
      task :list do
        puts stack_name
      end
    end

    def this_stack? name
      !name || name == stack_name
    end

  end
end
