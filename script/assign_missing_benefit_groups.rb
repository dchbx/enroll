require 'csv'

filename = "#{Rails.root}/shop_report_errors_fix_bgas_only.csv"

def choose_plan_year(hbx_enrollment,employer)
  effective_date = hbx_enrollment.effective_on
  potential_plan_years = []
  employer.plan_years.each do |py|
    start_date = py.start_on
    end_date = py.end_on
    coverage_range = (start_date..end_date)
    if coverage_range.include?(effective_date)
      potential_plan_years << py
    else
      potential_plan_years << nil
    end
  end
  potential_plan_years.compact!.uniq!
  return potential_plan_years[0]
end

def choose_benefit_group_assignment(census_employee,hbx_enrollment)
  effective_date = hbx_enrollment.effective_on
  bgas = []
  census_employee.benefit_group_assignments.each do |bga|
    start_date = bga.start_on
    end_date = bga.end_on
    if end_date.nil?
      end_date = (start_date+1.year)-1.day
    end
    coverage_range = (start_date..end_date)
    if coverage_range.include?(effective_date)
      bgas << bga
    else
      bgas << nil
    end
  end
  bgas = bgas.compact.uniq!
  unless bgas.nil?
    return bgas[0]
  else
    return nil
  end
end

CSV.foreach(filename, headers: true) do |row|
  hbx_enrollment = HbxEnrollment.by_hbx_id(row['Enrollment ID'].strip).first
  employer = Organization.where(legal_name: row['Employer'].strip).first.employer_profile
  plan_year = choose_plan_year(hbx_enrollment,employer)
  person = hbx_enrollment.subscriber.person
  census_employee = CensusEmployee.where(employer_profile_id: employer._id, first_name: /#{person.first_name}/i, last_name: /#{person.last_name}/i).first
  benefit_group_assignment = choose_benefit_group_assignment(census_employee,hbx_enrollment)
  if benefit_group_assignment.blank?
    benefit_group_assignment = BenefitGroupAssignment.new
    benefit_group_assignment.benefit_group = plan_year.benefit_groups.first
    benefit_group_assignment.start_on = plan_year.start_on
    census_employee.benefit_group_assignments.push(benefit_group_assignment)
    benefit_group_assignment.hbx_enrollment = hbx_enrollment
  end
  hbx_enrollment.benefit_group_assignment = benefit_group_assignment
  hbx_enrollment.benefit_group = benefit_group_assignment.benefit_group
  benefit_group_assignment.save!
  hbx_enrollment.save!
end