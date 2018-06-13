require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'
class CancelPlanYearsGroup < MongoidMigrationTask
  def migrate
    begin
      file_name = ENV['file_name'].to_s
      CSV.foreach("#{Rails.root}/#{file_name}", headers: true) do |row|
      date =(Date.strptime(row['start_on'],'%m/%d/%Y').to_date)
      aasm_state = row['aasm_state']
      if !EmployerProfile.find_by_fein(row['FEIN']).present?

        puts "employer not found #{row['FEIN']}"  unless Rails.env.test?
      else  
        plan_year=EmployerProfile.find_by_fein(row['FEIN']).plan_years.where(start_on: date, aasm_state: aasm_state).first
        if plan_year.present?
            if ["application_ineligible","renewing_application_ineligible", "publish_pending"].include? plan_year.aasm_state
              enrollments = all_enrollments(plan_year.benefit_groups)
              enrollments.each { |enr| enr.cancel_coverage! if enr.may_cancel_coverage? }
              puts "canceled enrollments for ineligible plan year" unless Rails.env.test?
              plan_year.revert_application! if plan_year.may_revert_application?
              plan_year.cancel! if plan_year.may_cancel?
              puts "canceled ineligible plan year for #{row['FEIN']}" unless Rails.env.test?
            else
              system("rake migrations:cancel_plan_year feins='#{row['FEIN']}' plan_year_state='#{row['aasm_state']}'")
              puts "Plan Year Cancelled for #{row['FEIN']}" unless Rails.env.test?
            end
        else
          puts "Plan Year not found for ER #{row['FEIN']} with the #{row['start_on']} and #{row['aasm_state']}" unless Rails.env.test?
        end  
      end
    end
  end
end
    def all_enrollments(benefit_groups=[])
      id_list = benefit_groups.collect(&:_id).uniq
      families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
      families.inject([]) do |enrollments, family|
      enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).to_a
    end
  end
end