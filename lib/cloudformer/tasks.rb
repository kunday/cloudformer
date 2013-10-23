require 'cloudformer/version'
require 'cloudformer/stack'

module Cloudformer
 class Tasks < Rake::TaskLib
   def initialize(stack_name)
     @stack_name = stack_name
     @stack =Stack.new(stack_name)
     define_tasks
   end

   private
   def define_tasks
     define_create_task
     define_delete_task
     define_events_task
     define_status_task
     define_outputs_task
   end

   def define_create_task
     desc "Apply Stack with Cloudformation script and parameters."
     task :apply do
       @stack.apply
     end
   end
   def define_delete_task
     desc "Delete stack from CloudFormation"
     task :delete do
       @stack.delete
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
 end
end
