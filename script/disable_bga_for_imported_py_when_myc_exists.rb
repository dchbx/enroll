benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(
  :"source_kind" => :mid_plan_year_conversion,
  :"benefit_applications.aasm_state" => :imported
)

benefit_sponsorships.each do |sponsorship|
  myc_application = sponsorship.benefit_applications.where(aasm_state: :active).first
  imported_application = sponsorship.benefit_applications.where(aasm_state: :imported).first

  if myc_application.blank? || imported_application.blank?
    puts "No MYC Plan year present ER: #{sponsorship.organization.legal_name}"
    next
  end

  sponsorship.census_employees.each do |census_employee|
    census_employee.benefit_group_assignments.where(
      :"benefit_package_id".in => imported_application.benefit_packages.map(&:id),
      :"is_active" => true
    ).each do |bga|
      if bga.update_attributes(is_active: false)
        puts "Disabling BGA for #{census_employee.full_name} of ER: #{sponsorship.organization.legal_name}"
      end
    end

    if census_employee.active_benefit_group_assignment.blank? || imported_application.benefit_packages.map(&:id).include?(census_employee.active_benefit_group_assignment.id)
      myc_benefit_package = myc_application.benefit_packages.first
      myc_bga = census_employee.benefit_group_assignments.where(
        :"benefit_package_id".in => myc_application.benefit_packages.map(&:id)
      ).first || census_employee.benefit_group_assignments.build(benefit_package_id: myc_benefit_package.id, start_on: myc_benefit_package.start_on)
      if myc_bga.persisted?
        puts "Set is active true on existing myc BGA EE: #{census_employee.full_name} ER: #{sponsorship.organization.legal_name}"
      else
        puts "Created new BGA for myc. EE: #{census_employee.full_name} ER: #{sponsorship.organization.legal_name}"
      end
      myc_bga.update_attributes(is_active: true)
    end
  end
end
