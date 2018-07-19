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
      attribute :employment_terminated_on, Date
      attribute :is_business_owner, String
      
      # template attributes
      attribute :benefit_group, String
      attribute :plan_year, String
      attribute :newly_designated, String

      attribute :email, Forms::EmailForm
      attribute :address, BenefitSponsors::Organizations::OrganizationForms::AddressForm

      validates_presence_of :employee_relationship, :email
    end
  end
end
