# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize

require File.join(Rails.root, "lib/mongoid_migration_task")

class CensusEmployeesOverlappingBenefitGroupAssignmentsReport < MongoidMigrationTask
  def all_census_employees
    @all_census_employees ||= CensusEmployee.all
  end

  def ce_with_overlapping_benefit_assignments(census_employee)
    overlapping_bgas = []
    if census_employee.benefit_group_assignments.count >= 2
      census_employee.benefit_group_assignments.each do |target_bga|
        census_employee.benefit_group_assignments.each do |bga|
          next if bga.id == target_bga.id
          # TODO: Need to figure out what to do if no end on date
          bga_end_on = bga.end_on || bga.start_on.next_year.prev_day
          if (bga&.start_on&.to_date..bga_end_on.to_date).cover?(target_bga&.start_on&.to_date) ||
             (bga&.start_on&.to_date..bga_end_on.to_date).cover?(target_bga&.end_on&.to_date)
            overlapping_bgas << bga unless overlapping_bgas.include?(bga)
          end
        end
      end
    end
    {
      census_employee: census_employee,
      benefit_group_assignments: overlapping_bgas
    }
  end

  def migrate
    puts("Beginning census employee with overlapping Benefit Group Assignments report generation.") unless Rails.env.test?
    Dir.mkdir("census_employees_overlapping_bgas_report") unless File.exist?("census_employees_overlapping_bgas_report")
    file_name = "#{Rails.root}/census_employees_overlapping_bgas_report_#{TimeKeeper.datetime_of_record.strftime('%m_%d_%Y_%H_%M_%S')}.csv"

    logger = Logger.new("#{Rails.root}/log/census_employees_overlapping_bgas_report.log") unless Rails.env.test?
    logger.info "Script Start for census_employees_overlapping_bgas_report_#{TimeKeeper.datetime_of_record}" unless Rails.env.test?

    CSV.open(file_name, 'w') do |csv|
      puts("Beginning to write to overlapping BGA CSV.") unless Rails.env.test?
      field_names = %w[first_name last_name employer_fein aasm_state bga_1_id bga_1_start bga_1_end bga_2_id bga_2_start bga_2_end bga_3_id bga_3_start bga_3_end bga_4_id bga_4_start bga_4_end bga_5_id bga_5_start bga_5_end]
      csv << field_names
      all_census_employees.no_timeout.each do |census_employee|
        result = ce_with_overlapping_benefit_assignments(census_employee)
        # Need to skip unless there are multiple
        next unless result[:benefit_group_assignments].length >= 2
        csv << [
          result[:census_employee].first_name,
          result[:census_employee].last_name,
          result[:census_employee]&.employee_role&.employer_profile&.fein || result[:census_employee]&.employee_role&.employer_profile&.legal_name,
          result[:census_employee].aasm_state
        ] + result[:benefit_group_assignments].map do |bga|
              [bga.id.to_s, bga.start_on.to_s, bga.end_on.to_s]
            end.flatten
      end
    end
  end
  puts("Generation of overlapping benefit group assignments report complete.") unless Rails.env.test?
end

# rubocop:enable Metrics/AbcSize
