module Djin
  class Executor
   def call(*tasks)
     tasks.each do |task|
       run task.build_command if task.build_command
       run task.command
     end
   end

   private

   def run(command)
     system command
   end
  end
end
