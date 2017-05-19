module UIHelpers
  module WorkflowHelper
    def workflow_form_for(model, &block)
      path, method = if model.new_record?
        [send("step_#{model.class.name.pluralize.underscore.gsub('/', '_')}_path"), :post]
      else
        [send("step_#{model.class.name.underscore.gsub('/', '_')}_path", model), :put]
      end

      form_tag path, method: method do
        yield
      end
    end

    def previous_step_for
      send("go_to_step_#{@model.class.name.underscore.gsub('/', '_')}_path", @model.id, @current_step.to_i - 1)
    end
  end
end
