module UIHelpers
  module Workflow
    class Cell
      attr_accessor :gutter, :text, :type, :values, :disabled, :name, :options, :fields, :identifier, :attribute, :model, :accessor, :required, :label, :placeholder, :value, :checked, :for, :id, :prompt, :support_text_key, :class_names

      def initialize(attributes)
        @gutter = attributes['gutter']
        @text = attributes['text']
        @type = attributes['type']
        @values = attributes['values']
        @options = attributes['options'] || {}
        @fields = attributes['fields']
        @identifier = attributes['identifier']
        @model = attributes['model']
        @attribute = attributes['attribute']
        @accessor = attributes['accessor']
        @disabled = attributes['disabled']
        @required = attributes['required']
        @name = attributes['name']
        @label = attributes['label']
        @placeholder = attributes['placeholder']
        @value = attributes['value']
        @checked = attributes['checked']
        @for = attributes['for']
        @id = attributes['id']
        @prompt = attributes['prompt']
        @support_text_key = attributes['support_text_key']
        @class_names = attributes['classNames'] ? attributes['classNames'] : ''
      end

      def name_attribute(field=nil)
        "#{@model}[#{attribute}]"
      end
    end
  end
end
