require 'csv'

namespace :reports do
  namespace :shop do

    include ActionView::Helpers::NumberHelper

    desc "Invoices data export"
    task :employer_invoices, [:billing_date] => :environment do |task, args|

      @billing_date = Date.strptime(args[:billing_date], "%m/%d/%Y")
      @carriers = CarrierProfile.all.inject({}){|hash, carrier| hash[carrier.id] = carrier.legal_name; hash}
      @plans = Plan.where({market: 'shop', active_year: @billing_date.year}).inject({}){|data, plan| data[plan.id] = plan.name; data}
      @plan_carrier_mapping = Plan.where({market: 'shop', active_year: @billing_date.year}).inject({}){|data, plan| data[plan.id] = plan.carrier_profile_id; data}

      organizations = Organization.all.where(:"employer_profile.plan_years" => {
        :$elemMatch => {
          :start_on => @billing_date,
          :open_enrollment_start_on.lt => TimeKeeper.date_of_record,
          :aasm_state.in => (PlanYear::PUBLISHED + PlanYear::RENEWING_PUBLISHED_STATE)
        }})

      count = 0

      CSV.open("#{Rails.root}/public/invoice_reprot.csv", "w", force_quotes: true) do |csv|

        csv << ["EE first name","EE last name","Employer Type","ER legal name","ER FEIN","Benefit Group","SSN","Date of Birth","Date of Hire","Employment status","Plan Name","Carrier Name","Effective Date","Enrollment Status","Coverage Kind","No. Of Enrollees","Employee Cost", "Employer Contribution","Total Premium"]
        organizations.each do |organization|
          employer_profile = organization.employer_profile
          puts "Processing #{employer_profile.legal_name}"

          enrollments = employer_profile.enrollments_for_billing(@billing_date)
          enrollments.each do |enrollment|
            csv << build_invoice_row(enrollment, employer_profile)
          end
          count += 1
        end
      end

      puts "processed #{count} employers"
    end

    def build_invoice_row(enrollment, employer_profile)
      employee = enrollment.census_employee

      data = [
        employee.first_name,
        employee.last_name,
        employer_type(employer_profile),
        employer_profile.legal_name,
        employer_profile.fein,
        enrollment.benefit_group.title,
        employee.ssn,
        format_date(employee.dob),
        format_date(employee.hired_on),
        employment_status(employee.aasm_state),
        @plans[enrollment.plan_id],
        @carriers[@plan_carrier_mapping[enrollment.plan_id]],
        format_date(enrollment.effective_on),
        enrollment.aasm_state.to_s.humanize.titleize,
        enrollment.coverage_kind,
        enrollment.hbx_enrollment_members.count{|member| member.covered? },
        number_to_currency(enrollment.total_employee_cost),
        number_to_currency(enrollment.total_employer_contribution),
        number_to_currency(enrollment.total_premium)
      ]

      data
    end

    def employer_type(employer_profile)
      if employer_profile.profile_source.to_s == 'conversion'
        'Conversion'
      else
        py = employer_profile.plan_years.detect{|py| (PlanYear::PUBLISHED + PlanYear::RENEWING_PUBLISHED_STATE).include?(py.aasm_state.to_s) && py.start_on == @billing_date}

        if py.blank?
          raise 'error'
        end

        if PlanYear::RENEWING_PUBLISHED_STATE.include?(py.aasm_state.to_s)
          'Renewing'
        else
          'Newly Registered'
        end
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
  end
end
