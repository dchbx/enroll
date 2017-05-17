namespace :migrations do
  task :create_published_plan_year_for_sae => :environment do
    organization = Organization.where(fein: /133798158/).last
    employer_profile = organization.employer_profile
    reference_plan = Plan.where(active_year: 2016, hios_id: /86052DC0440013-01/).last
    elected_plans = Plan.valid_shop_health_plans("carrier", "53e67210eb899a4603000004", 2016)
    plan_year = employer_profile.plan_years.build(
      start_on: Date.new(2016,12,1),
      end_on: Date.new(2017,11,30),
      open_enrollment_start_on: Date.new(2016,10,13),
      open_enrollment_end_on: Date.new(2016,11,15)
    )

    benefit_group = plan_year.benefit_groups.build(
      title: "#{plan_year.start_on.year} #{reference_plan.coverage_kind.capitalize} Benefit Group",
      description: "#{plan_year.start_on.year} #{reference_plan.coverage_kind.capitalize} Benefit Group for #{organization.legal_name}",
      plan_option_kind: "single_carrier",
      carrier_for_elected_plan: "53e67210eb899a4603000004",
      reference_plan_id: reference_plan.id,
      elected_plans: elected_plans,
      effective_on_offset: 0,
      effective_on_kind: "first_of_month",
      terminate_on_kind: "end_of_month"
    )

    rbs = benefit_group.build_relationship_benefits
    rbs.each {|rb| rb.premium_pct = 100.00 if rb.relationship == "employee" }

    plan_year.save
    # assign benefit group assignments if any census employee present
    census_employees = employer_profile.census_employees
    census_employees.each do |census_employee|
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new({benefit_group_id: benefit_group.id , start_on: plan_year.start_on})
    end
    plan_year.force_publish!
  end


  task :create_published_plan_year_for_iron_vine => :environment do

    org = Organization.where(fein: /262316330/).last
    empr = org.employer_profile
    if org.present?
      rp = Plan.where(active_year: 2016, hios_id: /78079DC0220022-01/).last
      eps = [rp]
      py = empr.plan_years.build(
        start_on: Date.new(2016,12,1),
        end_on: Date.new(2017,11,30),
        open_enrollment_start_on: Date.new(2016,10,13),
        open_enrollment_end_on: Date.new(2016,11,15),
        fte_count: 31
      )

      bg = py.benefit_groups.build(
        title: "#{py.start_on.year} #{rp.coverage_kind.capitalize} Benefit Group",
        description: "#{py.start_on.year} #{rp.coverage_kind.capitalize} Benefit Group for #{org.legal_name}",
        plan_option_kind: "single_plan",
        carrier_for_elected_plan: "53e67210eb899a4603000004",
        reference_plan_id: rp.id,
        elected_plans: eps,
        effective_on_offset: 0,
        effective_on_kind: "first_of_month",
        terminate_on_kind: "end_of_month"
      )

      rbs = bg.build_relationship_benefits
      rbs.each {|rb| rb.premium_pct = 100.00 if rb.relationship != "child_26_and_over" }

      py.save

      # assign benefit group assignments if any census employee present
      ces = empr.census_employees
      ces.each do |census_employee|
        census_employee.benefit_group_assignments << BenefitGroupAssignment.new({benefit_group_id: bg.id , start_on: py.start_on})
      end
      py.force_publish!
    end

  end
end