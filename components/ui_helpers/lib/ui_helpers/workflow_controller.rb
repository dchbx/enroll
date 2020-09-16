# frozen_string_literal: true

require 'ui_helpers/workflow/steps'

module UIHelpers
  module WorkflowController
    extend ActiveSupport::Concern

    included do
      # anything you would want to do in every controller, for example: add a class attribute
      #class_attribute :class_attribute_available_on_every_controller, instance_writer: false

      before_action :find_or_create, only: :step
      before_action :load_steps, only: :step
      before_action :load_support_texts, only: :step
      before_action :current_step, only: :step
    end

    module ClassMethods
      # notice: no self.method_name here, because this is being extended because ActiveSupport::Concern was extended
      #def make_this_controller_fantastic
      #  before_action :some_instance_method_available_on_every_controller # to be available on every controller
      #  after_action :another_instance_method_available_on_every_controller # to be available on every controller
      #  include FantasticStuff
      #end
    end

    def step
      render 'step'
    end

    def load_steps
      filename = lookup_context.find_template("#{controller_path}/steps.yml").identifier
      @steps = Workflow::Steps.new YAML.load_file(filename)
    end

    def load_support_texts
      file_path = lookup_context.find_template("financial_assistance/shared/support_text.yml").identifier
      @support_texts = YAML.load_file(file_path)
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
