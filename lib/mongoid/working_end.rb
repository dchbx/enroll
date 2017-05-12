module Mongoid
  module WorkingEnd

    def unset_sparse(field)
      normalized = database_field_name(field)
      attributes.delete(normalized)
    end


    module ClassMethods
      extend ActiveSupport::Concern

      # Use for embedded docs
      def all
      end

      def first
        all.first
      end

      def last
        all.last
      end

      def find(id)
        organizations = Organization.where("employer_profile._id" => BSON::ObjectId.from_string(id))
        organizations.size > 0 ? organizations.first.employer_profile : nil
      rescue
        log("Can not find employer_profile with id #{id}", {:severity => "error"})
        nil
      end


      # TODO: Automatically add counter field if it doesn't exist
      def counter_cache(options)
        name = options[:name]
        counter_field = options[:field]

        after_create do |document|
          relation = document.send(name)
          relation.collection.update(relation._selector, {'$inc' => {counter_field.to_s => 1}}, {:multi => true})
        end

        after_destroy do |document|
          relation = document.send(name)
          relation.collection.update(relation._selector, {'$inc' => {counter_field.to_s => -1}}, {:multi => true})
        end
      end
    end
  end
end