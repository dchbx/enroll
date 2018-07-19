module BenefitSponsors
  module PlanDesigns
    class CompositeTask < Task

      def initialize(name)
        super(name)
        @subtasks = []
      end

      def add_subtask(new_task)
        @subtasks << new_task
        new_task.parent = self
      end

      def <<(new_task)
        add_subtask(new_task)
      end

      def remove_subtask(task)
        @subtasks.delete(task)
        task.parent = nil
      end

      def [](index)
        @subtasks[index]
      end

      def []=(index, new_task)
        @subtasks[index] = new_task
      end

      def process
        @subtasks.each do |task|
          task.new.process
        end
      end
    end
  end
end
