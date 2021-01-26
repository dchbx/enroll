# frozen_string_literal: true

module Dry
  module StructExtended

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def to_hash(object, type = self)
        type.schema.each_with_object({}) do |key, res|
          name = key.name
          attr = key.type
          if array?(attr)
            values = ::Array.wrap(object.public_send(name))
            res[name] = values.map { |value_item| serialize(value_item, attr.member) }
          elsif bool?(attr)
            value = object.public_send("#{name}?")
            res[name] = value
          else
            value = object.public_send(name)
            res[name] = serialize(value, attr)
          end
        end
      end

      def serialize(object, type)
        complex?(type) ? to_hash(object, type) : object
      end

      def complex?(attribute)
        attribute.respond_to?(:<) && attribute < Dry::Struct
      end

      def bool?(attribute)
        attribute.primitive?(true)
      end

      def array?(attribute)
        attribute.primitive?([])
      end
    end
  end
end