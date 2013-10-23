require 'cloudformer/version'
require 'cloudformer/stack'

module Cloudformer
 class Tasks < Rake::TaskLib
   def initialize(stack_name)
     @stack_name = stack_name
     define_tasks
   end

   private
   def define_tasks
     define_create_task
   end

   def define_create_task
     desc "Update Stack with Cloudformation script and parameters."
     task :create do
       Stack.new(stack_name)
     end
   end
 end
end
