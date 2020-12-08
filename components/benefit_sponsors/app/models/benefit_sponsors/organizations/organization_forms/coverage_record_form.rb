module BenefitSponsors
  module Organizations
    class OrganizationForms::CoverageRecordForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :encrypted_ssn, String
      attribute :dob, String
      attribute :hired_on, String
      attribute :is_applying_coverage, Boolean

      validates_presence_of :is_applying_coverage
    end
  end
end
