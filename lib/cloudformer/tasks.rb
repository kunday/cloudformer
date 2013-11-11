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

   attr_accessor :template, :parameters, :disable_rollback

   private
   def define_tasks
     define_create_task
     define_delete_task
     define_events_task
     define_status_task
     define_outputs_task
     define_recreate_task
     define_stop_task
     define_start_task
   end

   def define_create_task
     desc "Apply Stack with Cloudformation script and parameters."
     task :apply do
       @stack.apply(template, parameters, disable_rollback)
     end
   end
   def define_delete_task
     desc "Delete stack from CloudFormation"
     task :delete do
      begin
        @stack.delete
      rescue
        puts "Stack deleted successfully."
      end
     end
   end
   def define_status_task
     desc "Get the deployed app status."
     task :status do
       @stack.status
     end
   end
   def define_events_task
     desc "Get the recent events from the stack."
     task :events do
       @stack.events
     end
   end
   def define_outputs_task
     desc "Get the outputs of stack."
     task :outputs do
       @stack.outputs
     end
   end
   def define_recreate_task
     desc "Recreate stack."
     task :recreate => [:delete, :apply, :outputs]
   end

   def define_stop_task
    desc "Stop EC2 instances in stack."
    task :stop do
      @stack.stop_instances
    end
   end

   def define_start_task
    desc "Start EC2 instances in stack."
    task :start do
      @stack.start_instances
    end
   end
 end
end
