namespace :migrations do
  task :conversion_12000, [:file] => :environment do |task, args|

    puts "Processing ...." unless Rails.env.test?
    organization = Organization.where(fein: /521247182/).last
    employer_profile = organization.employer_profile

    puts "updating employer profile source" unless Rails.env.test?
    employer_profile.profile_source = "conversion"
    employer_profile.registered_on = Date.new(2015,9,1)
    employer_profile.save
    puts "successfully updated employer profile source to: #{employer_profile.profile_source}." unless Rails.env.test?

    puts "updating 2016 plan year state." unless Rails.env.test?
    py_2016 = employer_profile.plan_years.first
    py_2016.aasm_state = "renewing_enrolled"
    py_2016.save
    puts "successfully updated 2016 plan year state to #{py_2016.aasm_state}." unless Rails.env.test?

    puts "creating 2015 plan year" unless Rails.env.test?

    reference_plan = Plan.where(active_year: 2015, hios_id: /86052DC0520006-01/).last
    elected_plans = Plan.valid_shop_health_plans("carrier", "53e67210eb899a4603000004", 2015)
    plan_year = employer_profile.plan_years.build(
      start_on: Date.new(2015,12,1),
      end_on: Date.new(2016,11,30),
      open_enrollment_start_on: Date.new(2015,10,13),
      open_enrollment_end_on: Date.new(2015,11,15)
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
    rbs.each {|rb| rb.premium_pct = 50.00 }

    plan_year.aasm_state = "enrolled"
    plan_year.save
    puts "successfully created 2015 plan year in EA." unless Rails.env.test?
  end
end