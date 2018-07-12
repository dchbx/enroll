module BenefitSponsors
  module Serializers
    class PhoneSerializer < ActiveModel::Serializer
      attributes :kind, :area_code, :number, :extension, :office_kind_options, :id
      attribute :id, if: :is_persisted?


      def is_persisted?
        object.persisted?
      end

      def office_kind_options
        object.office_kinds
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
