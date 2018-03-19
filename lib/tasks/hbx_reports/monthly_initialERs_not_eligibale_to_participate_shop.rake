# Monthly implementation list of initial Employers that do not meet eligibility to participate in SHOP
# Business Rules for Qualified Initial Employers:
# 1. They have no enrollees
# 2. The only enrollee is listed as the owner of the company
# 3. The primary address is not a Washington DC address
# 4. The percentage of employees that submit an enrollment or waive is less that 2/3 (67%)

#this report should only be produced for the current month that enrollments are being processed.
#e.g.,given that the report in generated on 12/11 only 1/1 ERs will populate on the report

#call this rake task as:rake reports:shop:initial_ERs_not_qualified_to_shop["01/01/2017"]
require 'csv'
namespace :reports do
  namespace :shop do
    desc "List of initial_ERs not_meet eligibility to participate in shop"
    task :initial_ERs_not_qualified_to_shop,[:effective_date] => :environment do |task, args|
      count = 0
      effective_date = Date.strptime(args[:effective_date], "%m/%d/%Y")
      initial_employers=Organization.where(:"employer_profile.plan_years" => { :$elemMatch => { :"start_on" => effective_date, :"aasm_state".in => PlanYear::PUBLISHED + ['draft']}})
      field_names  = %w(
                        Employer_Name
                        Employer_Fein
                        Employee_HBX_ID
                        Number_of_Enrolled_Employee
                        Participation_Rate
                        Is_owner_the_only_enrollee?(Y/N)
                        Non-DC_primary_address?(Y/N)
                        )
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/List_of_initial_ERs_not_meet_eligibility_to_participate_in_shop.csv"
      CSV.open(file_name, "w") do |csv|
        csv << field_names
        initial_employers.each do |employer|
          census_employees = employer.employer_profile.census_employees
          condition_1= census_employees.size==0
          condition_2= (census_employees.size==1 && census_employees.first.is_business_owner)
          condition_3=!employer.employer_profile.is_primary_office_local?
          plan_year=employer.employer_profile.find_plan_year_by_effective_date(effective_date)
          if plan_year.present?
            if plan_year.eligible_to_enroll_count==0
              condition_4=1
            else
              condition_4= (plan_year.total_enrolled_count/plan_year.eligible_to_enroll_count<2/3)
            end
          end
          if condition_1 || condition_2 || condition_3 || condition_4
              csv << [
                    employer.legal_name,
                    employer.fein,
                    employer.hbx_id,
                    employer.employer_profile.census_employees.active.size,
                    (plan_year.blank? ? '' : plan_year.employee_participation_percent),
                    employer.employer_profile.census_employees.size==1 ? 'yes' : 'no',
                    employer.employer_profile.is_primary_office_local? ? 'yes' : 'no'
                ]
              count += 1
          end
        end
        puts "Waiver Report for Employees Generated on #{Date.today}, Total initial Employers count #{count} and Employer information output file: #{file_name}"
      end # CSV close
    end
  end
end