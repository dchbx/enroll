# frozen_string_literal: true

module AccessPolicies
  class EmployerProfile
    attr_accessor :user

    def initialize(user)
      @user = user
    end

    def authorize_show(employer, controller)
      return true if user.has_hbx_staff_role? || is_broker_for_employer?(employer.id) || is_general_agency_staff_for_employer?(employer.id)
      person = user.person

      unless person.employer_staff_roles.active.empty?
        ep_ids = user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s)
        controller.redirect_to_first_allowed unless ep_ids.include?(employer.id.to_s)
        return true
      end
      controller.redirect_to_new
    end

    def authorize_index(broker_agency_id, controller)
      return true if user.has_hbx_staff_role?
      return if (user.has_broker_role? || user.has_broker_agency_staff_role?) && !broker_agency_id.blank?
      controller.redirect_to_new
    end

    def is_broker_for_employer?(employer_id)
      person = user.person
      return false unless person.broker_role || person.broker_agency_staff_roles.present?
      if person.broker_role
        employers = ::EmployerProfile.find_by_writing_agent(person.broker_role)
      else
        broker_agency_profiles = person.broker_agency_staff_roles.map {|role| ::BrokerAgencyProfile.find(role.broker_agency_profile_id) }
        employers = broker_agency_profiles.map { |bap| ::EmployerProfile.find_by_broker_agency_profile(bap) }.flatten
      end
      employers.map(&:id).map(&:to_s).include?(employer_id.to_s)
    end

    def authorize_edit(employer_profile, controller)
      return true if @user.has_hbx_staff_role? || is_broker_for_employer?(employer_profile.id) || is_general_agency_staff_for_employer?(employer_profile.id)
      return true if Person.staff_for_employer(employer_profile).include?(@user.person)
      controller.redirect_to_new and return
    end

    def is_general_agency_staff_for_employer?(employer_id)
      return false if user.person.general_agency_staff_roles.blank?
      ga_id = user.person.general_agency_staff_roles.last.general_agency_profile.id
      return false if ga_id.nil? || employer_id.nil?
      plan_design_organizations = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_sponsor(employer_id)
      plan_design_organizations.each do |a|
        return true if a.general_agency_profile.present? && (a.general_agency_profile.id == ga_id)
      end
    end
  end
end
