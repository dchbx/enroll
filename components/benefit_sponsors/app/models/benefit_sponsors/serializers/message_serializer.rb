module BenefitSponsors
  module Serializers
    class MessageSerializer < ActiveModel::Serializer
      attributes :sender_id

      def is_persisted?
        object.persisted?
      end

      # provide defaults(if any needed) that were not set no Model
      def attributes(*args)
        hash = super
        unless object.persisted?
          
        end
        hash
      end
    end
  end
end
