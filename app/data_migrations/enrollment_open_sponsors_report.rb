require File.join(Rails.root, "lib/mongoid_migration_task")

# frozen_string_literal: true
class EnrollmentOpenSponsorsReport < MongoidMigrationTask

  def migrate
    from_date = Date.strptime(ENV['from_date'].to_s, "%m/%d/%Y")
    to_date = Date.strptime(ENV['to_date'].to_s, "%m/%d/%Y")

    detailed_report(from_date, to_date)
  end

  def detailed_report_field_names(from_date)
    [
      "Employer Legal Name",
      "Employer FEIN",
      "Employer HBX ID",
      "Previous year effective_date",
      "Previous year State",
      "Renewal effective_date",
      "Renewal State",
      "First name",
      "Last Name",
      "Roster status",
      "Hbx ID",
      "Previous year enrollment",
      "Previous year enrollment kind",
      "Previous year plan",
      "Previous year effective_date",
      "Previous year status",
      "Renewal enrollment",
      "Renewal enrollment kind",
      "Renewal plan",
      "Renewal effective_date",
      "Renewal status",
      "Reasons"
    ]
  end

  def enrollment_open_sponsors_for(from_date, to_date)
    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:benefit_applications => {
                                                                     :$elemMatch => {
                                                                       :predecessor_id => { :$exists => true, :$ne => nil },
                                                                       :aasm_state.in => [:enrollment_open, :enrollment_closed, :enrollment_eligible, :enrollment_extended, :active],
                                                                       :workflow_state_transitions => {
                                                                         "$elemMatch" => {
                                                                           "to_state" => :enrollment_open,
                                                                           "transition_at" => {"$gte" => TimeKeeper.start_of_exchange_day_from_utc(from_date), "$lt" => TimeKeeper.end_of_exchange_day_from_utc(to_date)}
                                                                         }
                                                                       }
                                                                     }
    })
  end

  def enrollment_reason(enrollment_prev_year, enrollment_current_year)
    current_year_state = enrollment_current_year.try(:aasm_state)
    prev_year_state = enrollment_prev_year.try(:aasm_state)
    rp_id = enrollment_prev_year.try(:product).try(:renewal_product_id)
    cp_id = enrollment_current_year.try(:product).try(:id)

    if current_year_state == 'auto_renewing'
      "Successfully Generated"
    elsif current_year_state == "coverage_selected"
      "Plan was manually selected for the current year" unless rp_id == cp_id
    elsif ["inactive","renewing_waived"].include?(current_year_state)
      "enrollment is waived"
    elsif current_year_state.nil? && prev_year_state.in?(HbxEnrollment::WAIVED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
      "Previous plan has waived or terminated and did not generate renewal"
    elsif current_year_state.nil? && ["coverage_selected", "coverage_enrolled"].include?(prev_year_state)
      "Enrollment plan was changed either for current year or previous year" unless rp_id == cp_id
    else
      return ''
    end
  end

  def detailed_report(from_date, to_date)
    file_name = "Employees_missing_renewals_#{from_date.strftime('%m_%d_%Y')}_to_#{to_date.strftime('%m_%d_%Y')}.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << detailed_report_field_names(from_date)
      enrollment_open_sponsors_for(from_date, to_date).no_timeout.each do |ben_spon|
        puts "Processing...#{ben_spon.legal_name}"

        ben_app_prev_year = ben_spon.benefit_applications.where(:"effective_period.min".lt => from_date, aasm_state: :active).first
        ben_app_curr_year = ben_spon.benefit_applications.where({
          :"effective_period.min".gte => from_date,
          :predecessor_id => { :$exists => true, :$ne => nil },
          :aasm_state.in => [:enrollment_open, :enrollment_closed, :enrollment_eligible, :enrollment_extended, :active]
        }).first

        ben_spon.census_employees.non_term_and_pending.no_timeout.each do |census|
          if census.employee_role.present?
            family = census.employee_role.person.primary_family
          elsif Person.by_ssn(census.ssn).present? && Person.by_ssn(census.ssn).employee_roles.select{|e| e.census_employee_id == census.id && e.is_active == true}.present?
            person = Person.by_ssn(census.ssn).first
            family = person.primary_family
          end

          renewal_enrollments = []
          if family.present?
            benefit_package_ids = ben_app_curr_year.present? ? ben_app_curr_year.benefit_packages.map(&:id) : []
            renewal_enrollments = family.active_household.hbx_enrollments.where({
              :sponsored_benefit_package_id.in => benefit_package_ids,
              :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::WAIVED_STATUSES)
            })
          end

          next if renewal_enrollments.size > 0

          enrollments = []
          if family.present?
            packages_prev_year = ben_app_prev_year.present? ? ben_app_prev_year.benefit_packages.map(&:id) : []
            enrollments = family.active_household.hbx_enrollments.where(:sponsored_benefit_package_id.in => packages_prev_year, :aasm_state.nin => ["shopping", "coverage_canceled", "coverage_expired"])
          end

          next if enrollments.blank?

          %w(health dental).each do |kind|
            next unless ben_app_curr_year.benefit_packages.any?{|bp| bp.sponsored_benefit_for(kind).present? }
            
            if family
              enrollment_prev_year = enrollments.where(coverage_kind: kind).first
              enrollment_current_year = renewal_enrollments.where(coverage_kind: kind).first
            end

            next unless enrollment_prev_year

            data = [ben_spon.profile.legal_name,
                    ben_spon.profile.fein,
                    ben_spon.profile.hbx_id,
                    ben_app_prev_year&.effective_period&.min,
                    ben_app_prev_year&.aasm_state,
                    ben_app_curr_year.effective_period.min,
                    ben_app_curr_year.aasm_state,
                    census.first_name,
                    census.last_name,
                    census.aasm_state,
                    census&.employee_role&.person&.hbx_id || Person.by_ssn(census.ssn).first&.hbx_id,
                    enrollment_prev_year&.hbx_id,
                    enrollment_prev_year&.coverage_kind,
                    enrollment_prev_year&.product&.hios_id,
                    enrollment_prev_year&.effective_on,
                    enrollment_prev_year&.aasm_state,
                    enrollment_current_year&.hbx_id,
                    enrollment_current_year&.coverage_kind,
                    enrollment_current_year&.product&.hios_id,
                    enrollment_current_year&.effective_on,
                    enrollment_current_year&.aasm_state]
            data += [enrollment_reason(enrollment_prev_year, enrollment_current_year)]
            csv << data
          end
        end
      end
    end
  end
end