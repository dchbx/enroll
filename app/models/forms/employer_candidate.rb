# frozen_string_literal: true

module Forms
  class EmployerCandidate
    include ActiveModel::Model
    include ActiveModel::Validations

    include FeinField
    include EmployerFields

    validates_presence_of :fein, :allow_blank => nil
    validates_presence_of :legal_name, :allow_blank => nil

    validate :does_not_match_a_company_with_existing_staff

    validates :fein,
              length: { minimum: 9, maximum: 9, message: " must be 9 digits" },
              numericality: true

    def match_employer
      ::EmployerProfile.find_by_fein(fein)
    end

    def does_not_match_a_company_with_existing_staff
      if match_employer.present? && match_employer.staff_roles.present?
        errors.add(
          :base,
          "This company already has a managing staff associated"
        )
      end

      true
    end

  end
end
