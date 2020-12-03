require File.join(Rails.root, "lib/mongoid_migration_task")

# frozen_string_literal: true
class EnrollmentOpenSponsorsReport < MongoidMigrationTask

  def migrate
    from_date = Date.strptime(ENV['from_date'].to_s, "%m/%d/%Y")
    to_date = Date.strptime(ENV['to_date'].to_s, "%m/%d/%Y")

    detailed_report(from_date, to_date)
  end

  def detailed_report_field_names
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
    state_transition_query = {
      :to_state => :enrollment_open,
      :transition_at => {
        :$gte => TimeKeeper.start_of_exchange_day_from_utc(from_date),
        :$lt => TimeKeeper.end_of_exchange_day_from_utc(to_date)
      }
    }

    benefit_application_query = {
      :predecessor_id => {:$exists => true, :$ne => nil},
      :aasm_state.in => [:enrollment_open, :enrollment_closed, :enrollment_eligible, :enrollment_extended, :active],
      :workflow_state_transitions => { :$elemMatch => state_transition_query }
    }

    BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:benefit_applications => {:$elemMatch => benefit_application_query})
  end

  def enrollment_reason(enrollment_prev_year, enrollment_current_year)
    current_year_state = enrollment_current_year.try(:aasm_state)
    prev_year_state = enrollment_prev_year.try(:aasm_state)
    return non_enrolled_reason(prev_year_state) unless current_year_state

    if ["inactive","renewing_waived"].include?(current_year_state)
      "enrollment is waived"
    elsif current_year_state == 'auto_renewing'
      "Successfully Generated"
    elsif current_year_state == "coverage_selected"
      rp_id = enrollment_prev_year.try(:product).try(:renewal_product_id)
      cp_id = enrollment_current_year.try(:product).try(:id)

      "Plan was manually selected for the current year" unless rp_id == cp_id
    end
  end

  def non_enrolled_reason(prev_year_state)
    if prev_year_state.in?(HbxEnrollment::WAIVED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
      "Previous plan has waived or terminated and did not generate renewal"
    elsif ["coverage_selected", "coverage_enrolled"].include?(prev_year_state)
      "Employer plan offerings might have changed for current year"
    end
  end

  def data_row(ben_app_prev_year, ben_app_curr_year, census, enrollment_prev_year, enrollment_current_year)
    [
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
      enrollment_current_year&.aasm_state,
      enrollment_reason(enrollment_prev_year, enrollment_current_year)
    ]
  end

  def sponsor_fields(ben_spon)
    [
      ben_spon.profile.legal_name,
      ben_spon.profile.fein,
      ben_spon.profile.hbx_id
    ]
  end

  def find_family(census)
    if census.employee_role.present?
      census.employee_role.person.primary_family
    elsif Person.by_ssn(census.ssn).present? && Person.by_ssn(census.ssn).employee_roles.select{|e| e.census_employee_id == census.id && e.is_active == true}.present?
      person = Person.by_ssn(census.ssn).first
      person.primary_family
    end
  end

  def find_active_application(sponsorship, from_date)
    sponsorship.benefit_applications.where(:"effective_period.min".lt => from_date, aasm_state: :active).first
  end

  def find_renewal_application(sponsorship, from_date)
    sponsorship.benefit_applications.where({
                                             :"effective_period.min".gte => from_date,
                                             :predecessor_id => { :$exists => true, :$ne => nil },
                                             :aasm_state.in => [:enrollment_open, :enrollment_closed, :enrollment_eligible, :enrollment_extended, :active]
                                           }).first
  end

  def enrollments_by_application(family, application, states)
    family.active_household.hbx_enrollments.where({
                                                    :sponsored_benefit_package_id.in => application.benefit_packages.map(&:id),
                                                    :aasm_state.in => states
                                                  })
  end

  def find_enrollments(family, ben_app_curr_year, ben_app_prev_year)
    renewal_enrollments = []
    renewal_enrollments = enrollments_by_application(family, ben_app_curr_year, (HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES + HbxEnrollment::WAIVED_STATUSES)) if ben_app_curr_year

    enrollments = family.active_household.hbx_enrollments.where({
                                                                  :sponsored_benefit_package_id.in => ben_app_prev_year.benefit_packages.map(&:id),
                                                                  :aasm_state.nin => ["shopping", "coverage_canceled", "coverage_expired"]
                                                                })

    [renewal_enrollments, enrollments]
  end

  def detailed_report(from_date, to_date)
    file_name = "Employees_missing_renewals_#{from_date.strftime('%m_%d_%Y')}_to_#{to_date.strftime('%m_%d_%Y')}.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << detailed_report_field_names
      enrollment_open_sponsors_for(from_date, to_date).no_timeout.each do |ben_spon|
        puts "Processing...#{ben_spon.legal_name}"

        ben_app_prev_year = find_active_application(ben_spon, from_date)
        ben_app_curr_year = find_renewal_application(ben_spon, from_date)

        ben_spon.census_employees.non_term_and_pending.no_timeout.each do |census|
          family = find_family(census)

          next unless family
          next unless ben_app_prev_year

          renewal_enrollments, enrollments = find_enrollments(family, ben_app_curr_year, ben_app_prev_year)
          next if renewal_enrollments.present? || enrollments.blank?

          %w[health dental].each do |kind|
            next unless ben_app_curr_year.benefit_packages.any?{|bp| bp.sponsored_benefit_for(kind).present? }

            if family
              enrollment_prev_year = enrollments.where(coverage_kind: kind).first
              enrollment_current_year = renewal_enrollments.where(coverage_kind: kind).first
            end

            next unless enrollment_prev_year

            csv << (sponsor_fields(ben_spon) + data_row(ben_app_prev_year, ben_app_curr_year, census, enrollment_prev_year, enrollment_current_year))
          end
        end
      end
    end
  end
end
