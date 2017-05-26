class CongressionalRenewalCleanup

  EMPLOYERS = [
  ]

  def families(benefit_groups = [])
    id_list = benefit_groups.collect(&:_id).uniq
    Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
  end

  def found_active_coverage?(renewal, active_enrollments)
    active_enrollments.any? {|enrollment|
      enrollment.effective_on == renewal.effective_on && enrollment.coverage_kind == renewal.coverage_kind && enrollment.benefit_group.employer_profile == renewal.benefit_group.employer_profile
    }
  end

  def found_other_er_active_coverage?(renewal, active_enrollments)
    active_enrollments.any? {|enrollment|
      enrollment.effective_on == renewal.effective_on && enrollment.coverage_kind == renewal.coverage_kind && enrollment.benefit_group.employer_profile != renewal.benefit_group.employer_profile
    }
  end

  def format_date(date)
    return nil if date.blank?
    date.strftime("%m/%d/%Y")
  end

  def headers
    ["Employer Name", "Employer FEIN", "EE First Name", "EE Last Name", "EE Roster Status", "Employment Terminated On", "Enrollment HBX ID", "Coverage Start", "Terminated On","Enrollment Status", "Plan Name", "Plan HIOS"]
  end

  def csv_row(enrollment)
    employee = (enrollment.benefit_group_assignment || enrollment.employee_role).census_employee
    plan = enrollment.plan
    [
      employee.employer_profile.legal_name,
      employee.employer_profile.fein,
      employee.first_name,
      employee.last_name,
      employee.aasm_state.camelcase,
      format_date(employee.employment_terminated_on),
      enrollment.hbx_id,
      format_date(enrollment.effective_on),
      format_date(enrollment.terminated_on),
      enrollment.aasm_state,
      plan.try(:name),
      plan.try(:hios_id)
    ]
  end

  def cancel_er_switch_renewals
    EMPLOYERS.each do |fein|
      employer_profile = EmployerProfile.find_by_fein(fein)
      plan_year = employer_profile.active_plan_year

      CSV.open("congressional_er_#{fein}_renewal_cancellations_multi_ers.csv", "w") do |csv|
        csv << headers
       
        families = families(plan_year.benefit_groups)
        puts "Processing #{employer_profile.legal_name}---found #{families.size} families"
        bg_ids = plan_year.benefit_groups.map(&:id)

        families.each do |family|
          enrollments =  family.active_household.hbx_enrollments.where(effective_on: (plan_year.start_on..plan_year.end_on)).shop_market
          passive_renewals = enrollments.where(:aasm_state.in => (HbxEnrollment::RENEWAL_STATUSES + ["renewing_waived"]), :benefit_group_id.in => bg_ids)
          active_enrollments = enrollments.where(:aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES))

          passive_cancels = passive_renewals.select do |renewal|
            found_other_er_active_coverage?(renewal, active_enrollments)
          end

          if passive_cancels.present?
            (active_enrollments + passive_cancels).each do |enrollment|
              begin
                csv << csv_row(enrollment)
              rescue Exception => e
                puts "Failed #{enrollment.hbx_id} -- #{e.inspect}"
              end
            end
          end

          passive_cancels.each do |renewal|
            renewal.cancel_coverage! if renewal.may_cancel_coverage?
          end
        end
      end
    end
  end

  def cancel_passive_renewals
    EMPLOYERS.each do |fein|
      employer_profile = EmployerProfile.find_by_fein(fein)
      plan_year = employer_profile.active_plan_year
      
      CSV.open("congressional_er_#{fein}_renewal_cancellations.csv", "w") do |csv|
        csv << headers

        families = families(plan_year.benefit_groups)
        puts "Processing #{employer_profile.legal_name}---found #{families.size} families"
        bg_ids = plan_year.benefit_groups.map(&:id)

        families.each do |family|
          enrollments =  family.active_household.hbx_enrollments.where(effective_on: (plan_year.start_on..plan_year.end_on)).shop_market
          passive_renewals = enrollments.where(:aasm_state.in => (HbxEnrollment::RENEWAL_STATUSES + ["renewing_waived"]), :benefit_group_id.in => bg_ids)
          active_enrollments = enrollments.where(:aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES))

          passive_cancels = passive_renewals.select do |renewal|
            found_active_coverage?(renewal, active_enrollments)
          end

          if passive_cancels.present?
            (active_enrollments + passive_cancels).each do |enrollment|
              begin
                csv << csv_row(enrollment)
              rescue Exception => e
                puts "Failed #{enrollment.hbx_id} -- #{e.inspect}"
              end
            end
          end

          passive_cancels.each do |renewal|
            renewal.cancel_coverage! if renewal.may_cancel_coverage?
          end
        end
      end
    end
  end

  def cancel_renewals_on_terminated_employees
    EMPLOYERS.each do |fein|
      employer_profile = EmployerProfile.find_by_fein(fein)
      plan_year = employer_profile.active_plan_year
      
      CSV.open("congressional_er_#{fein}_renewal_cancellations.csv", "w") do |csv|
        csv << headers

        families = families(plan_year.benefit_groups)
        puts "Processing #{employer_profile.legal_name}---found #{families.size} families"
        bg_ids = plan_year.benefit_groups.map(&:id)

        families.each do |family|
          enrollments =  family.active_household.hbx_enrollments.where(effective_on: (plan_year.start_on..plan_year.end_on)).shop_market
          passive_renewals = enrollments.where(:aasm_state.in => (HbxEnrollment::RENEWAL_STATUSES + ["renewing_waived"]), :benefit_group_id.in => bg_ids)
     
          passive_cancels = passive_renewals.reject{|passive| passive.benefit_group_assignment.blank?}.select{|renewal|
           renewal.benefit_group_assignment.census_employee.employment_terminated_on.present? && renewal.benefit_group_assignment.census_employee.employment_terminated_on <= renewal.effective_on
          }

          if passive_cancels.present?
            passive_cancels.each do |enrollment|
              begin
                csv << csv_row(enrollment)
              rescue Exception => e
                puts "Failed #{enrollment.hbx_id} -- #{e.inspect}"
              end
            end
          end

          passive_cancels.each do |renewal|
            renewal.cancel_coverage! if renewal.may_cancel_coverage?
          end
        end
      end
    end
  end

  def begin_coverage
    EMPLOYERS.each do |fein|
      employer_profile = EmployerProfile.find_by_fein(fein)
      plan_year = employer_profile.active_plan_year

      CSV.open("congressional_er_#{fein}_begin_coverage.csv", "w") do |csv|
        csv << headers

        families = families(plan_year.benefit_groups)
        bg_ids = plan_year.benefit_groups.map(&:id)
        puts "Processing #{employer_profile.legal_name}---found #{families.size} families"

        families.each do |family|
          enrollments =  family.active_household.hbx_enrollments.where(effective_on: (plan_year.start_on..plan_year.end_on)).shop_market
          passive_renewals = enrollments.where(:aasm_state.in => (HbxEnrollment::RENEWAL_STATUSES + ["renewing_waived"]), :benefit_group_id.in => bg_ids)
          active_enrollments = enrollments.where(:aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES), :benefit_group_id.in => bg_ids)

          valid_passives = passive_renewals.select do |renewal|
            !found_active_coverage?(renewal, active_enrollments) && !found_other_er_active_coverage?(renewal, active_enrollments)
          end

          if valid_passives.present?
            (active_enrollments + valid_passives).each do |enrollment|
              begin
                csv << csv_row(enrollment)
              rescue Exception => e
                puts "Failed #{enrollment.hbx_id} -- #{e.inspect}"
              end
            end
          end

          valid_passives.each do |renewal|
            renewal.begin_coverage! if renewal.may_begin_coverage?
          end
        end
      end
    end
  end
end
