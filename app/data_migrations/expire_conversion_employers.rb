require File.join(Rails.root, "lib/mongoid_migration_task")

class ExpireConversionEmployers < MongoidMigrationTask

  def migrate
    CSV.open("#{Rails.root}/ConversionERExpiration_Results.csv", "w", force_quotes: true) do |csv|

      csv << ['FEIN', 'Legal Name', 'Conversion Employer', 'Plan Year Status(Before)', 'Plan Year Status(After)', "External Plan Year Status(Before)", "External Plan Year Status(After)"]

      CSV.foreach("#{Rails.root.to_s}/ConversionERExpiration.csv") do |row|

        fein = prepend_zeros(row[0].to_s, 9)
        start_on = Date.strptime(row[1].to_s, "%m/%d/%Y")
        employer = EmployerProfile.find_by_fein(fein)

        if employer.blank?
          puts "Employer Profile not found with fein #{fein}" unless Rails.env.test?
          next
        else
          puts "Processing (#{fein}) - #{employer.legal_name}" unless Rails.env.test?
        end

        csv << update_employer_plan_years(employer, start_on)
      end
    end
  end

  def update_employer_plan_years(employer, start_on)
    data = [employer.fein, employer.legal_name, employer.is_conversion?]

    if plan_year = employer.plan_years.where(:start_on => start_on).first
      data += [plan_year.aasm_state.camelcase]

      plan_year_enrollments(plan_year).each do |enrollment|
        enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
      end

      if plan_year.active?
        plan_year.update(aasm_state: 'renewing_enrolled')
      end

      plan_year.cancel_renewal! if plan_year.may_cancel_renewal?
      plan_year.cancel! if plan_year.may_cancel?
      data += [plan_year.aasm_state.camelcase]
    else
      data += [nil, nil]
    end

    if off_exchange_py = employer.plan_years.where(:start_on => start_on.prev_year).first
      data += [off_exchange_py.aasm_state.camelcase]
      off_exchange_py.conversion_expire! if off_exchange_py.may_conversion_expire?
      data += [off_exchange_py.aasm_state.camelcase]
    end

    data
  end

  def prepend_zeros(number, n)
    (n - number.to_s.size).times { number.prepend('0') }
    number
  end

  def plan_year_enrollments(plan_year)
    id_list = plan_year.benefit_groups.collect(&:_id).uniq

    families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
    families.inject([]) do |enrollments, family|
      enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).enrolled_and_renewal.to_a
    end
  end
end
