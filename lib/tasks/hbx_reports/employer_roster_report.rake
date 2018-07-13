require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employer plan year application status by effective date"
    task :employer_roster_report => :environment do
      include Config::AcaHelper

      organizations = BenefitSponsors::Organizations::Organization.employer_profiles.where(:"hbx_id".nin => [100101, 100102, 118510])
      build_csv_report('er_roster_report', 'ERROSTER', organizations)

      if !Settings.aca.state_abbreviation.downcase == "ma"
        organizations = BenefitSponsors::Organizations::Organization.employer_profiles.where(:"hbx_id".in => [100101, 100102, 118510])
        build_csv_report('congressional_er_roster_report', 'CONGRESSIONALERROSTER', organizations)
      end
    end
  end
end

def build_csv_report(file_name_DC, file_name_MA, organizations)
  file_path = fetch_file_format(file_name_DC, file_name_MA)

  CSV.open(file_path, "w", force_quotes: true) do |csv|
      csv << ["EE first name","EE last name","ER legal name","ER DBA name","ER FEIN","SSN","Date of Birth","Date of Hire","Date added to roster","Employment status", "Date of Termination", "Date Terminated on Roster", "Email","Address","Roster Status","EE's HIX ID","EE active health","active health HIOS ID","EE active dental","active dental HIOS ID","EE renewal health","renewal health HIOS ID","EE renewal dental","renewal dental HIOS ID"]

    @products_info = load_products

    organizations.each do |organization|
      begin
        employer_profile = organization.employer_profile
        next if employer_profile.census_employees.blank?
        employer_data = [organization.legal_name, organization.dba, organization.fein]

        employer_profile.census_employees.active.each do |active_employee|
          data = build_employee_row(active_employee, employer_data)
          csv << data
        end

        employer_profile.census_employees.terminated.each do |active_employee|
          data = build_employee_row(active_employee, employer_data)
          csv << data
        end
      rescue Exception => e
        puts e.message
      end
    end
  end
  puts "********** Report Finished ***********"
  if Rails.env.production?
    pubber = Publishers::Legacy::EmployerRosterReportPublisher.new
    pubber.publish URI.join("file://", file_path)
  end
end

def build_employee_row(employee, employer_data)
  data = [
    employee.first_name,
    employee.last_name
  ]
  data += employer_data
  data += [
    employee.ssn,
    format_date(employee.dob),
    format_date(employee.hired_on),
    format_date(employee.created_at),
    employment_status(employee.aasm_state)
  ]

  if employment_status(employee.aasm_state) == 'terminated'
    data << format_date(employee.employment_terminated_on)
    transition = employee.workflow_state_transitions.where(:to_state => 'employment_terminated').first
    data << (transition.present? ? format_date(transition.transition_at) : format_date(employee.updated_at))
  else
    data += ['', '']
  end

  data += [
    employee.email_address,
    employee.try(:address).try(:full_address) || '',
    employee.aasm_state.humanize,
    employee.employee_role.try(:hbx_id)
  ]

  if employee.active_benefit_group_assignment.present? &&  employee.employee_role.present?
    enrollments = employee.active_benefit_group_enrollments
    health_enrollment = enrollments.enrolled_and_waived.by_coverage_kind('health').first
    dental_enrollment = enrollments.enrolled_and_waived.by_coverage_kind('dental').first
    data += (health_enrollment.present? ? [health_enrollment.aasm_state, @products_info[health_enrollment.product_id.to_s]] : add_data(2,''))
    data += (dental_enrollment.present? ? [dental_enrollment.aasm_state, @products_info[dental_enrollment.product_id.to_s]] : add_data(2,''))
  else
    data += add_data(4,'')
  end

  if employee.renewal_benefit_group_assignment.present? &&  employee.employee_role.present?
    enrollments = employee.renewal_benefit_group_enrollments
    health_enrollment = enrollments.enrolled_and_waived.by_coverage_kind('health').first
    dental_enrollment = enrollments.enrolled_and_waived.by_coverage_kind('dental').first
    data += (health_enrollment.present? ? [health_enrollment.aasm_state, @products_info[health_enrollment.product_id.to_s]] : add_data(2,''))
    data += (dental_enrollment.present? ? [dental_enrollment.aasm_state, @products_info[dental_enrollment.product_id.to_s]] : add_data(2,''))
  else
    data += add_data(4,'')
  end

  data
end

def load_products
  current_year = TimeKeeper.date_of_record.year
  previous_year = current_year - 1
  next_year = current_year + 1

  plans = BenefitMarkets::Products::Product.aca_shop_market.by_state(Settings.aca.state_abbreviation)

  current_possible_plans = plans.where(:"application_period.min".in =>[
    Date.new(previous_year, 1, 1),
    Date.new(current_year, 1, 1),
    Date.new(next_year, 1, 1)
  ])

  current_possible_plans.inject({}) do |result, product|
    result[product.id.to_s] = product.hios_id
    result
  end
end

def employment_status(aasm_state)
  case aasm_state.to_s
  when 'employment_terminated'
    'terminated'
  when 'rehired'
    'rehired'
  else
    'active'
  end
end

def format_date(date)
  return '' if date.blank?
  date.strftime("%m/%d/%Y")
end

def add_data(count,expression)
  return Array.new(count,expression)
end
