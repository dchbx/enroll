module Notifier
  module MergeDataModels::TokenBuilder

    def settings_placeholders
      system_settings.inject([]) do |placeholders, (category, attribute_set)|
        attribute_set.each do |attribute|
          placeholders << {
            title: "#{category.to_s.humanize}: #{attribute.humanize}",
            target: ["Settings", category, attribute].join('.')
          }
        end
        placeholders
      end
    end
  
    def place_holders
      placeholders = []

      collections.each do |collection|
        placeholders << {
          title: "Loop: #{collection.humanize}",
          target: [parent_data_model, collection].join('.'),
          iterator: collection.singularize,
          type: 'loop'
        }

        if merge_model = self.class.attribute_set.detect{|e| e.name == collection.to_sym}
          get_editor_attributes(merge_model.type.member_type).each do |attribute|
            placeholders << {
              title: "&nbsp;&nbsp; #{attribute.to_s.humanize}",
              target: [collection.singularize, attribute.to_s].join('.'),
            }
          end
        end
      end

      conditions.each do |condition|
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
      attributes_hash[parent_data_model] = get_editor_attributes(self.class)

      self.class.attribute_set.select{|set| set.is_a?(Virtus::Attribute::EmbeddedValue)}.each do |embed|
        attributes_hash[embed.name] = get_editor_attributes(embed.type.primitive)
      end

      attributes_hash
    end

    def parent_data_model
      return @class_name if defined? @class_name
      @class_name = self.class.to_s.split('::').last.underscore.to_sym #self.class.class_name.underscore.to_sym
    end

    def system_settings
      {
        :site => %w(domain_name home_url help_url faqs_url main_web_address short_name byline long_name shop_find_your_doctor_url document_verification_checklist_url registration_path),
        :contact_center => %w(name alt_name phone_number fax tty_number alt_phone_number email_address small_business_email appeals),
        :'contact_center.mailing_address' => %w(name address_1 address_2 city state zip_code),
        :aca => %w(state_name state_abbreviation),
        :'aca.shop_market' => %w(valid_employer_attestation_documents_url binder_payment_due_on),
      }
    end
  end
end