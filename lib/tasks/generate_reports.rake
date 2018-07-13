require 'csv'

namespace :generate_reports do
  desc "export conversion employer attributes"
  task conversions_employers: :environment do
    attributes = %w(FEIN legal_name hbx_id)
    file_name = File.expand_path("#{Rails.root}/public/results_conversion_employers.csv")

    organizations = find_organizations
    puts "Found #{organizations.count} organizations"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << attributes
      organizations.each do |org|
        csv << attributes.map {|attr| org.send(attr)}
      end
    end
    puts "Successfully exported values placed the CSV under public Directory"
  end

  def find_organizations
    BenefitSponsors::Organizations::Organization.employer_profiles.includes(:benefit_sponsorships).select {|org| org.benefit_sponsorships.first.source_kind == :mid_plan_year_conversion}
  end

  def find_census_employees(organization)
    benefit_sponsorship = organization.benefit_sponsorships.first
    CensusEmployee.where(benefit_sponsors_employer_profile_id: organization.employer_profile.id, benefit_sponsorship_id: benefit_sponsorship.id)
  end

  def find_enrollment_policy_id(census_employee)
    person = census_employee.employee_role.person
    hbx_id = person.hbx_id
    family = person.primary_family
    hbx_enrollment = family.active_household.hbx_enrollments.select{ |enrollment| enrollment.sponsored_benefit_id.present? && enrollment.benefit_sponsorship_id.present? }.first
    policy_id = hbx_enrollment.hbx_id
    hios_id = hbx_enrollment.product.hios_id
    dependents_info = find_dependents_hbx_ids(family)
    [person.first_name, person.last_name, person.ssn, person.dob.to_s, hbx_id, policy_id, hios_id] + dependents_info
  end

  def find_dependents_hbx_ids(family)
    dependent_info = Array.new
    family_dependents = family.family_members.find_all {|family_member| !family_member.is_primary_applicant?}

    family_dependents.each do |family_member|
      person = family_member.person
      dependent_info.push person.first_name
      dependent_info.push person.last_name
      dependent_info.push person.ssn
      dependent_info.push person.dob.to_s
      dependent_info.push person.hbx_id
    end
    dependent_info
  end

  desc "export conversion census employee details"
  task conversion_employees: :environment do
    attributes = %w(fein legal_name census_employee_first_name census_employee_last_name census_employee_ssn census_employee_dob census_employee_hbx_id census_employee_policy_id hios_id)
    (1..6).each do |i|
      ["first name", "Last Name", "SSN", "DOB", "HBX ID"].each do |h|
        attributes.push "Dep#{i} #{h}"
      end
    end

    file_name = File.expand_path("#{Rails.root}/public/results_conversion_employees.csv")

    organizations = find_organizations
    puts "Started exporting values to CSV"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << attributes
      organizations.each do |organization|
        census_employees = find_census_employees(organization)
        census_employees.each do |census_employee|
          census_info = find_enrollment_policy_id(census_employee)
          csv << [organization.fein, organization.legal_name] + census_info
        end
      end
    end
    puts "Successfully generated report placed the CSV under public directory"
  end
end
