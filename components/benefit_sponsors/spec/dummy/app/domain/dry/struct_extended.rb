# frozen_string_literal: true

module Dry
  #This mixin is used to serialize data of an object
  # Include this mixin wherever necessary
  module StructExtended
   extend ActiveSupport::Concern

    #Methods used for converting object into a hash with matching dry struct
    class_methods do
      #This method takes object and dry struct class, which then
      # serialize the object and return the hash with the matching
      # dry struct schema. And this is a recursive function
      def to_hash(object, type = self)
        type.schema.each_with_object({}) do |key, res|
          name = key.name
          attr = key.type
          if array?(attr)
            values = ::Array.wrap(object.public_send(name))
            res[name] = values.map { |value_item| serialize(value_item, attr.member) if attr.respond_to?(:member) }
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