module Notifier
  module Services::TokenBuilder
  
    def placeholders
      placeholders = []

      model_builder.collections.each do |collection|
        placeholders << {
          title: "Loop: #{collection.humanize}",
          target: [parent_data_model, collection].join('.'),
          iterator: collection.singularize,
          type: 'loop'
        }

        if merge_model = model_builder.class.attribute_set.detect{|e| e.name == collection.to_sym}
          get_editor_attributes(merge_model.type.member_type).each do |attribute|
            placeholders << {
              title: "&nbsp;&nbsp; #{attribute.to_s.humanize}",
              target: [collection.singularize, attribute.to_s].join('.'),
            }
          end
        end
      end

      model_builder.conditions.each do |condition|
         placeholders << {
          title: "Condition: #{condition.humanize}",
          target: [parent_data_model, condition].join('.'),
          type: 'condition'
        }
      end

      placeholders
    end

    def editor_tokens
      editor_attributes.inject([]) do |data, (virtus_model_name, virtus_attributes)|
        virtus_attributes.each do |attribute|
          method_name = "#{virtus_model_name}.#{attribute}"
          if virtus_model_name != parent_data_model
            method_name = [parent_data_model, method_name].join('.')
          end
          data << ["#{virtus_model_name.to_s.humanize} - #{attribute.to_s.humanize}", method_name]
        end
        data
      end
    end

    def get_editor_attributes(virtus_model)
      virtus_model.attribute_set.select{|set| !set.is_a?(Virtus::Attribute::EmbeddedValue)}.collect(&:name)
    end

    def editor_attributes
      attributes_hash = {}
      attributes_hash[parent_data_model] = get_editor_attributes(model_builder.class)

      model_builder.class.attribute_set.select{|set| set.is_a?(Virtus::Attribute::EmbeddedValue)}.each do |embed|
        attributes_hash[embed.name] = get_editor_attributes(embed.type.primitive)
      end

      attributes_hash
    end

    def parent_data_model
      return @class_name if defined? @class_name
      @class_name = self.model_builder.class.to_s.split('::').last.underscore.to_sym #self.class.class_name.underscore.to_sym
    end
  end
end