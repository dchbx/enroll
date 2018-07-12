module BenefitSponsors
  module Locations
    class OfficeLocation
      include Mongoid::Document

      embedded_in :profile, class_name: "BenefitSponsors::Organizations::Profile"
      #embedded_in :plan_design_employer_profile, class_name: "BenefitSponsors::BenefitSponsorships::PlanDesignEmployerProfile"

      field :is_primary, type: Boolean, default: true

      embeds_one :address, class_name:"BenefitSponsors::Locations::Address", cascade_callbacks: true, validate: true
      accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true
      embeds_one :phone, class_name:"BenefitSponsors::Locations::Phone", cascade_callbacks: true, validate: true
      accepts_nested_attributes_for :phone, reject_if: :all_blank, allow_destroy: true

      validates_presence_of :address, class_name:"BenefitSponsors::Locations::Address"
      validates_presence_of :phone, class_name:"BenefitSponsors::Locations::Phone", if: :primary_or_branch?


      # validate :address_includes_county_for_employers_primary_location

      alias_method :is_primary?, :is_primary

      # remove organization references?

      # def address_includes_county_for_employers_primary_location
      #   return unless is_an_employer?
      #   if address.kind == 'primary' && address.county.blank?
      #     self.errors.add(:base, 'Employers must have a valid County for their primary office location')
      #   end
      # end

      def county
        address.present? ? address.county : ""
      end

      def zip
        address.present? ? address.zip : ""
      end



      # def parent
      #   self.organization
      # end

      # def is_an_employer?
      #   return false if organization.nil?
      #   organization.employer_profile.present?
      # end

      def primary_or_branch?
        ['primary', 'branch'].include? address.kind if address.present?
      end

      # TODO -- only one office location can be primary
      # def is_primary=(new_primary_value)
      #   if parent.present? && new_primary_value == true
      #     parent.office_locations.each { |loc| loc.is_primary == false unless loc == self }
      #   end
      # end

      def address_can_be_rejected?
        attributes["address"].blank? || attributes["address"]["zip"].blank?
      end

      def phone_can_be_rejected?
        attributes["phone"].blank? || attributes["phone"]["number"].blank?
      end
    end
  end

end
