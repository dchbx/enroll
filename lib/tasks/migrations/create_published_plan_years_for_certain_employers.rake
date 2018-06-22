# This rake task is used to create plan year for expection case with plan year info.

# RAILS_ENV=production bundle exec rake migrations:create_active_plan_year

namespace :migrations do

  desc "create plan year with info"

  task :create_active_plan_year => :environment do

    organization = Organization.where(fein: /520943763/).last
    employer_profile = organization.employer_profile
    if organization.present?
      reference_plan = Plan.where(active_year: 2018, hios_id: /94506DC0350001/).last
      # elected_plans = Plan.valid_shop_health_plans("carrier", "53e67210eb899a4603000004",2016).map(&:id) # single_carrier
      # elected_plans = Plan.by_active_year(2016).shop_market.health_coverage.by_carrier_profile(reference_plan.carrier_profile).and(hios_id: /86052DC0580001/).map(&:id) #single_plan
      elected_plans = Plan.valid_shop_by_metal_level("platinum").map(&:id)  # by metal level

      # no dental offering
      # dental_reference_plan = Plan.where(active_year: 2016, hios_id: /78079DC0340001/).last
      # dental_elected_plans = Plan.by_active_year(2016).shop_market.dental_coverage.by_carrier_profile(dental_reference_plan.carrier_profile).map(&:id)



      plan_year = employer_profile.plan_years.build(
          start_on: Date.new(2018,02,01),
          end_on: Date.new(2019,01,31),
          open_enrollment_start_on: Date.new(2018,01,01),
          open_enrollment_end_on: Date.new(2018,1,13),
          fte_count: 04
      )

      benefit_group = plan_year.benefit_groups.build(
          title: "BWSTATLAB-HEALTH PACKAGE(#{plan_year.start_on.year})",
          description: "",

          # health
          plan_option_kind: "metal_level",
          # carrier_for_elected_plan: "53e67210eb899a4603000004",
          reference_plan_id: reference_plan.id,
          elected_plan_ids: elected_plans,
          elected_dental_plan_ids: [],
          dental_reference_plan_id:''

          # no dental offering

          # dental_reference_plan_id: dental_reference_plan.id,
          # elected_dental_plan_ids: dental_elected_plans,
          # dental_plan_option_kind: "single_carrier",
          # carrier_for_elected_dental_plan:'53e67210eb899a4603000004',
          #
          # effective_on_offset: 60,
          # effective_on_kind: "first_of_month",
          # terminate_on_kind: "end_of_month",
          # is_congress: false

      )

      # health
      rbs = benefit_group.build_relationship_benefits
      rbs.each do |rb|
        if rb.relationship == "child_26_and_over"
          rb.offered = false
          rb.premium_pct = 0.0
        else
          rb.premium_pct = 50.00 if rb.relationship == "employee"
          rb.premium_pct = 50.0 if rb.relationship == "spouse"
          rb.premium_pct = 0.0 if rb.relationship == "domestic_partner"
          rb.premium_pct = 0.0 if rb.relationship == "child_under_26"
        end
      end

      # dental
      # dental_rbs = benefit_group.build_dental_relationship_benefits
      # dental_rbs.each do |rb|
      #   if rb.relationship == "child_26_and_over"
      #     rb.offered = false
      #   else
      #     rb.premium_pct = 100.00
      #   end
      # end

      if plan_year.save!
        puts "plan year created sucessfully"
      end

      # assign benefit group assignments if any census employee present
      ces = employer_profile.census_employees.active
      ces.each do |census_employee|
        puts "assigning benefit group assignment for census employees #{census_employee.full_name}"
        census_employee.benefit_group_assignments << BenefitGroupAssignment.new({benefit_group_id: benefit_group.id , start_on: plan_year.start_on})
        census_employee.benefit_group_assignments.where(start_on: plan_year.start_on).first.make_active  # making active benefit group assignment
        # fixing existing employee enrollments
        # if census_employee.employee_role.present?
        #   census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.each do |hbx|
        #     if hbx.effective_on.strftime('%Y-%m-%d') == "2016-07-01"
        #       # census employee has enrollemnts in coverage selected state with "2016-07-01" effective date, updating benefit group assignment and benfit group.
        #       hbx.update_attributes(benefit_group_id:benefit_group.id, benefit_group_assignment_id: census_employee.benefit_group_assignments.where(benefit_group_id:benefit_group.id).first.id)
        #     end
        #   end
        # end
      end

      if plan_year.may_force_publish?  # enrolling
        plan_year.force_publish!
        puts "force publishing plan year #{plan_year.aasm_state}"
      end

      if plan_year.may_activate? # to active state
        plan_year.activate!
        puts "activating published plan year #{plan_year.aasm_state}"
      end
    end

  end
end