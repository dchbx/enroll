require 'ui_helpers/workflow/steps'

module UIHelpers
  module WorkflowController
    extend ActiveSupport::Concern

    included do
      # anything you would want to do in every controller, for example: add a class attribute
      #class_attribute :class_attribute_available_on_every_controller, instance_writer: false

      before_filter :find_or_create, only: :step
      before_filter :load_steps, only: :step
      before_filter :load_support_texts, only: :step
      before_filter :current_step, only: :step
    end

    module ClassMethods
      # notice: no self.method_name here, because this is being extended because ActiveSupport::Concern was extended
      #def make_this_controller_fantastic
      #  before_filter :some_instance_method_available_on_every_controller # to be available on every controller
      #  after_filter :another_instance_method_available_on_every_controller # to be available on every controller
      #  include FantasticStuff
      #end
    end

    def step
      puts 'test'
      render 'step'
    end

    def load_steps
      @steps = Workflow::Steps.new YAML.load_file(Rails.root + "app/views/#{controller_path}/steps.yml")
    end

    def load_support_texts
      @support_texts = YAML.load_file("app/views/financial_assistance/shared/support_text.yml")
    end

    def current_step
      if params[:step]
        @current_step = @steps.find(params[:step].to_i)
      else
        @current_step ||= @steps.find(@model.workflow['current_step'] || 1)
      end
    end

    def find_or_create
      @model = find || create
    end
  end
end
