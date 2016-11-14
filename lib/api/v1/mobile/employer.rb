module Api
  module V1
    module Mobile
      class Employer < Base

        def initialize args={}
          super args
          @plan_year = @employer_profile.show_plan_year if @employer_profile
        end

        def employers_and_broker_agency
          return if organizations.empty?
          @employer_profiles = organizations.map { |o| o.employer_profile }
          broker_name = @user.person.first_name if @user.person.broker_role

          {broker_name: broker_name,
           broker_agency: @authorized[:broker_agency_profile].try(:legal_name),
           broker_agency_id: @authorized[:broker_agency_profile].id,
           broker_clients: marshall_employer_summaries} if @authorized[:broker_agency_profile]
        end

        def details
          @plan_year ? details_for_plan_year : basic_details
        end

        #
        # Private
        #
        private

        def details_for_plan_year
          enrollments = @employer_profile.enrollments_for_billing(@report_date) || []
          premium_amt_total = enrollments.map(&:total_premium).sum
          employee_cost_total = enrollments.map(&:total_employee_cost).sum
          employer_contribution_total = enrollments.map(&:total_employer_contribution).sum
          enrolled, waived, terminated = count_enrolled_waived_and_terminated_employees @plan_year

          basic_details num_enrolled: enrolled,
                        num_waived: waived,
                        num_terminated: terminated,
                        total_premium: premium_amt_total,
                        employer_contribution: employer_contribution_total,
                        employee_contribution: employee_cost_total
        end

        def basic_details num_enrolled: nil, num_waived: nil, num_terminated: nil, total_premium: nil,
                          employer_contribution: nil, employee_contribution: nil
          details = summary employer_profile: @employer_profile, year: @plan_year, num_enrolled: num_enrolled,
                            num_waived: num_waived, num_terminated: num_terminated
          details[:total_premium] = total_premium
          details[:employer_contribution] = employer_contribution
          details[:employee_contribution] = employee_contribution
          details[:active_general_agency] = @employer_profile.active_general_agency_legal_name # Note: queries DB
          details[:plan_offerings] = Hash[active_and_renewal_plan_years.map do |period, py|
            [period, py ? Api::V1::Mobile::PlanYear.new(plan_year: py).plan_offerings : nil]
          end]
          details
        end

        def count_enrolled_waived_and_terminated_employees plan_year
          return unless Api::V1::Mobile::PlanYear.new(plan_year: plan_year).employee_max?
          count_by_enrollment_status plan_year
        end

        def active_and_renewal_plan_years
          {active: detect_plan_in_states(::PlanYear::PUBLISHED),
           renewal: detect_plan_in_states(::PlanYear::RENEWING_PUBLISHED_STATE + ::PlanYear::RENEWING)}
          #TODO: renewal when appropriate, see employer_profiles_controller.sort_plan_years
        end

        def detect_plan_in_states states
          @employer_profile.plan_years.detect { |py| states.include? py.aasm_state }
        end

        def organizations
          @organizations ||= @authorized.has_key?(:broker_role) ? Organization.by_broker_role(@authorized[:broker_role].id) :
              Organization.by_broker_agency_profile(@authorized[:broker_agency_profile]._id)
        end

        def marshall_employer_summaries
          return [] if @employer_profiles.blank?
          staff_by_employer_id = Api::V1::Mobile::Staff.new(employer_profiles: @employer_profiles).keyed_by_employer_id
          @employer_profiles.map do |er|
            plan_year = er.show_plan_year
            enrolled, waived, terminated = open_enrollment_employee_count plan_year, TimeKeeper.date_of_record
            summary employer_profile: er,
                    year: plan_year,
                    num_enrolled: enrolled,
                    num_waived: waived,
                    num_terminated: terminated,
                    staff: staff_by_employer_id[er.id],
                    offices: er.organization.office_locations.select { |loc| loc.primary_or_branch? },
                    include_details_url: true
          end
        end

        # def staff
        #   StaffHelper.new members: Person.where(:employer_staff_roles => {
        #       '$elemMatch' => {
        #           employer_profile_id: {"$in": @employer_profiles.map(&:id)},
        #           :aasm_state.ne => :is_closed
        #       }
        #   })
        # end

        #
        # As a performance optimization, in the mobile summary API (list of all employers for a broker)
        # we only bother counting the subscribers if the employer is currently in OE
        #
        def open_enrollment_employee_count plan_year, as_of
          plan_year = Api::V1::Mobile::PlanYear.new plan_year: plan_year, as_of: as_of
          return unless plan_year.open_enrollment?
          count_by_enrollment_status plan_year
        end

        #
        # Alternative, faster way to calculate total_enrolled_count
        # Returns a list of number enrolled (actually enrolled, not waived) and waived
        # Check if the plan year is in renewal without triggering an additional query
        #
        def count_by_enrollment_status plan_year
          employee = Employee.new benefit_group: Api::V1::Mobile::BenefitGroup.new(plan_year: plan_year)
          employee.count_by_enrollment_status
        end

        def summary employer_profile:, year:, num_enrolled: nil, num_waived: nil, num_terminated: nil, staff: nil,
                    offices: nil, include_details_url: false
          renewals_offset_in_months = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months
          summary = {
              employer_name: employer_profile.legal_name,
              employees_total: employer_profile.roster_size,
              open_enrollment_begins: year ? year.open_enrollment_start_on : nil,
              open_enrollment_ends: year ? year.open_enrollment_end_on : nil,
              plan_year_begins: year ? year.start_on : nil,
              renewal_in_progress: year ? year.is_renewing? : nil,
              renewal_application_available: year ? (year.start_on >> renewals_offset_in_months) : nil,
              renewal_application_due: year ? year.due_date_for_publish : nil,
              binder_payment_due: '',
              minimum_participation_required: year ? year.minimum_enrolled_count : nil,
          }
          summary[:employees_enrolled] = num_enrolled if num_enrolled
          summary[:employees_waived] = num_waived if num_waived
          summary[:employees_terminated] = num_terminated if num_terminated

          summary[:contact_info] = add_contact_info(staff || [], offices || []) if staff || offices
          add_urls! employer_profile, summary if include_details_url
          summary
        end

        def add_urls! employer_profile, summary
          url_helper = Rails.application.routes.url_helpers
          summary[:employer_details_url] = url_helper.api_v1_mobile_api_employer_details_path employer_profile.id
          summary[:employee_roster_url] = url_helper.api_v1_mobile_api_employee_roster_path employer_profile.id
        end

        #TODO null handling
        def add_contact_info staff, offices
          staff.map do |s|
            {first: s.first_name,
             last: s.last_name,
             phone: s.work_phone.to_s,
             mobile: s.mobile_phone.to_s,
             emails: [s.work_email_or_best]}
          end + offices.map do |loc|
            {first: loc.address.kind.capitalize,
             last: "Office",
             phone: loc.phone.to_s,
             address_1: loc.address.address_1,
             address_2: loc.address.address_2,
             city: loc.address.city,
             state: loc.address.state,
             zip: loc.address.zip}
          end
        end

      end
    end
  end
end