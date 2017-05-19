module UIHelpers
  module Workflow
    class Cell
      attr_accessor :gutter, :text, :type, :values, :disabled, :name, :options, :fields, :identifier, :attribute, :model, :required, :label, :placeholder, :value, :checked, :for, :id

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
        @disabled = !!attributes['disabled'] ? false : attributes['disabled']
        @required = !!attributes['required'] ? false : attributes['required']
        @name = attributes['name']
        @label = attributes['label']
        @placeholder = attributes['placeholder']
        @value = attributes['value']
        @checked = attributes['checked']
        @for = attributes['for']
        @id = attributes['id']
      end

      def name_attribute(field=nil)
        "attributes[#{attribute}]"
      end
    end
  end
end

