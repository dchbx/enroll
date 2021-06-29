# frozen_string_literal: true

module ComposedModel
  def self.included(base)
    base.class_eval do
      extend ComposedModel::ComposedModelClassMethods
    end
  end

  def validate_collection_and_propagate_errors(collection_name, objs)
    objs.each_with_index do |obj, idx|
      obj.valid?
      obj.errors.each do |attr, err|
        errors.add(validate_collection_error_key_name(collection_name, idx, attr), err)
      end
    end
  end

  def validate_collection_error_key_name(collection_name, idx, property)
    "#{collection_name}_attributes[#{idx}][#{property}]"
  end

  module ComposedModelClassMethods
    def composed_of_many(name, klass_name, do_validation_on_collection = false)
      class_eval(<<-RUBYCODE)
        def #{name}=(vals)
          @#{name} ||= []
          if !vals.nil?
             @#{name} = vals
          end
          @#{name}
        end

        def #{name}
          @#{name} ||= []
        end

        def #{name}_attributes
          #{name}.map(&:attributes)
        end

        def #{name}_attributes=(vals)
          if vals.nil?
            @#{name} = []
            return []
          end
          @#{name} = vals.map { |v_attrs| #{klass_name}.new(v_attrs) }
          #{name}_attributes
        end
      RUBYCODE
      if do_validation_on_collection
        class_eval(<<-RUBYCODE)
          validate :#{name}_validation_steps

          def #{name}_validation_steps
            objs_to_validate = #{name}
            validate_collection_and_propagate_errors("#{name}",objs_to_validate)
          end
        RUBYCODE
      end
    end
  end
end
