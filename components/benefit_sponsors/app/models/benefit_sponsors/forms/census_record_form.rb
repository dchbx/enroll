module BenefitSponsors
  module Forms
    class CensusRecordForm

      include ActiveModel::Validations
      include Virtus.model

      attribute :employer_assigned_family_id, String
      attribute :employee_relationship, String
      attribute :last_name, String
      attribute :first_name, String
      attribute :middle_name, String
      attribute :name_sfx, String
      attribute :ssn, String
      attribute :dob, String
      attribute :gender, String
      attribute :hired_on, String
      attribute :employment_terminated_on, String
      attribute :is_business_owner, String
      attribute :no_ssn_allowed, Boolean
      
      # template attributes
      attribute :benefit_group, String
      attribute :plan_year, String
      attribute :newly_designated, String

      attribute :email, Forms::EmailForm
      attribute :address, BenefitSponsors::Organizations::OrganizationForms::AddressForm

      validates_presence_of :employee_relationship, :email
      validate :date_format

      def dob=(val)
        super(val.strftime("%m/%d/%Y")) if val
      end

      def date_format
        errors.add(:base, "DOB: #{dob}") if dob &.include?('Invalid Format')
        errors.add(:base, "Hired On: #{hired_on}") if hired_on &.include?('Invalid Format')
        errors.add(:base, "Employment Terminated On: #{employment_terminated_on}") if employment_terminated_on &.include?('Invalid Format')
      end
    end
  end
end
