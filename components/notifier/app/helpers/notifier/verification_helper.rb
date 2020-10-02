module Notifier
  module VerificationHelper
    include ApplicationHelper

    def aqhp_citizen_status(status)
      case status
      when "US"
        "US Citizen"
      when "LP"
        "Lawfully Present"
      when "NC"
        "US Citizen"
      else
        ""
      end
    end

    def uqhp_citizen_status(status)
      case status
      when "us_citizen"
        "US Citizen"
      when "alien_lawfully_present"
        "Lawfully Present"
      when "indian_tribe_member"
        "US Citizen"
      when "lawful_permanent_resident"
        "Lawfully Present"
      when "naturalized_citizen"
        "US Citizen"
      else
        "Ineligible Immigration Status"
      end
    end

    def unverified_individual_hash(person, due_date, uqhp)
      first_name = uqhp ? person.first_name.titleize : person['first_name'].titleize
      last_name = uqhp ? person.last_name.titleize : person['last_name'].titleize
      age = uqhp ? person.age_on(TimeKeeper.date_of_record) : calculate_age_by_dob(Date.strptime(datum["dob"], '%m/%d/%Y'))
      Notifier::MergeDataModels::Dependent.new({ first_name: individual.first_name.titleize, last_name: individual.last_name.titleize, due_date: due_date, age: individual.age_on(TimeKeeper.date_of_record)})
    end

    def outstanding_verification_types(person)
      person.consumer_role.outstanding_verification_types.map(&:type_name)
    end

    def ssn_outstanding?(person, uqhp)
      if uqhp
        outstanding_verification_types(person).include?("Social Security Number")
      else
        person["ssn_doc_needed"].try(:upcase) == "Y"
      end
    end

    def lawful_presence_outstanding?(person, uqhp)
      if uqhp
        outstanding_verification_types(person).include?('Citizenship')
      else
        person["citizenship_doc_needed"].try(:upcase) == "Y"
      end
    end

    def immigration_status_outstanding?(person, uqhp)
      if uqhp        
        outstanding_verification_types(person).include?('Immigration status')
      else
        person["immigration_doc_needed"].try(:upcase) == "Y"
      end
    end

    def american_indian_status_outstanding?(person, uqhp)
      return false unless uqhp

      outstanding_verification_types(person).include?('American Indian Status')
    end

    def residency_outstanding?(person, uqhp)
      return false unless uqhp

      outstanding_verification_types(person).include?('DC Residency')
    end

    def income_outstanding?(person, uqhp)
      return false if uqhp

      person["income_doc_needed"].try(:upcase) == "Y"
    end

    def other_coverage_outstanding?(person, uqhp)
      return false if uqhp

      person["other_coverage_doc_needed"].try(:upcase) == "Y"
    end

    def ivl_citizen_status(uqhp_notice, status)
      uqhp_notice ? uqhp_citizen_status(status) : aqhp_citizen_status(status)
    end

    def enrollments(family)
      HbxEnrollment.where(family_id: family.id, :aasm_state.nin => ['coverage_canceled', 'shopping', 'inactive', 'coverage_terminated']).select do |hbx_enrollment|
        !hbx_enrollment.is_shop? && (hbx_enrollment.terminated_on.blank? || hbx_enrollment.terminated_on >= TimeKeeper.date_of_record)
      end
    end

    def check_for_unverified_individuals(family)
      outstanding_people = []
      return outstanding_people unless family

      family_members = enrollments(family).inject([]) do |family_members, enrollment|
        family_members += enrollment.hbx_enrollment_members.map(&:family_member)
      end.uniq

      people = family_members.map(&:person).uniq
      people.each do |person|
        outstanding_people << person if person.consumer_role.outstanding_verification_types.present?
      end

      outstanding_people.uniq!
    end
  end
end