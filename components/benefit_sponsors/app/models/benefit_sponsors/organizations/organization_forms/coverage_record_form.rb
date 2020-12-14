# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    module OrganizationForms
      class CoverageRecordForm
        include Virtus.model
        include ActiveModel::Validations

        attribute :ssn, String
        attribute :dob, String
        attribute :gender, String
        attribute :hired_on, String
        attribute :is_applying_coverage, Boolean

        attribute :address, ::BenefitSponsors::Organizations::OrganizationForms::AddressForm
        attribute :email, ::BenefitSponsors::Forms::EmailForm

        validates_presence_of :is_applying_coverage
      end
    end
  end
end
