require_relative 'base'
require_relative 'mobile_api_helper'

module Api
  module V1
    class Employer < Base
      include Api::V1::MobileApiHelper

      def staff
        Staff.new members: Person.where(:employer_staff_roles => {
            '$elemMatch' => {
                employer_profile_id: {"$in": @employer_profiles.map(&:id)},
                :aasm_state.ne => :is_closed
            }
        })
      end

      def organization
        broker_role = @user.person.broker_role
        if @broker_agency_id && (@user.has_broker_agency_staff_role? || @user.has_hbx_staff_role?)
          broker_agency_profile = BrokerAgencyProfile.find @broker_agency_id
          organization = Organization.by_broker_agency_profile(broker_agency_profile._id) if broker_agency_profile
          #TODO fix security hole
        elsif broker_role
          broker_agency_profile = broker_role.broker_agency_profile
          organization = Organization.by_broker_role broker_role.id
        end
        yield broker_agency_profile, organization, broker_role
      end

      def summaries
        all_staff_by_employer_id = staff.by_employer_id
        @employer_profiles.map do |er|
          plan_year = er.show_plan_year
          enrolled, waived, terminated = open_enrollment_employee_count plan_year, TimeKeeper.date_of_record
          employer_summary employer_profile: er,
                           year: plan_year,
                           num_enrolled: enrolled,
                           num_waived: waived,
                           num_terminated: terminated,
                           staff: all_staff_by_employer_id[er.id],
                           offices: er.organization.office_locations.select { |loc| loc.primary_or_branch? },
                           include_details_url: true
        end
      end

      #
      #
      #
      private

      #
      # As a performance optimization, in the mobile summary API (list of all employers for a broker)
      # we only bother counting the subscribers if the employer is currently in OE
      #
      def open_enrollment_employee_count plan_year, as_of
        return unless plan_year && as_of &&
            plan_year.open_enrollment_start_on &&
            plan_year.open_enrollment_end_on &&
            plan_year.open_enrollment_contains?(as_of) &&
            plan_year.employer_profile.census_employees.count < 100

        # Alternative, faster way to calculate total_enrolled_count
        # Returns a list of number enrolled (actually enrolled, not waived) and waived
        # Check if the plan year is in renewal without triggering an additional query
        count_employees_by_enrollment_status Employee.benefit_group_assignments BenefitGroup.new plan_year: plan_year
      end

    end
  end
end