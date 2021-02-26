require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_product_spec_helpers"

RSpec.describe "insured/group_selection/new.html.erb" do
  after :all do
    DatabaseCleaner.clean
  end

  let(:adapter) { instance_double(GroupSelectionPrevaricationAdapter) }
  context "coverage selection", dbclean: :after_each do

  let(:site) { BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market }
  let(:benefit_market) { site.benefit_markets.first }
  let(:effective_period) { (effective_period_start_on..effective_period_end_on) }
  let!(:current_benefit_market_catalog) do
    BenefitSponsors::ProductSpecHelpers.construct_simple_benefit_market_catalog(site, benefit_market, effective_period)
    benefit_market.benefit_market_catalogs.where(
      "application_period.min" => effective_period_start_on
    ).first
  end

  include_context "setup initial benefit application"

  let(:effective_period_start_on) { current_effective_date }
  let(:effective_period_end_on) { effective_period_start_on + 1.year - 1.day }

  let(:service_areas) do
    ::BenefitMarkets::Locations::ServiceArea.where(
      :active_year => current_benefit_market_catalog.application_period.min.year
    ).all.to_a
  end

  let(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.where(
      :active_year => current_benefit_market_catalog.application_period.min.year
    ).first
  end
  let(:current_effective_date)  { (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year }

    let(:person) { FactoryBot.create(:person, is_incarcerated: false, us_citizen: true) }
    let(:employee_role) { FactoryBot.build_stubbed(:employee_role) }
    let(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package ) }    
    let(:benefit_group) { current_benefit_package }
    let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
    let(:family_member1) { double("family member 1", id: "family_member", primary_relationship: "self", dob: Date.new(1990, 10, 10), full_name: "member", person: person) }
    let(:family_member2) { double("family member 2", id: "family_member", primary_relationship: "parent", dob: Date.new(1990, 10, 10), full_name: "member", person: family_person_2) }
    let(:family_member3) { double("family member 3", id: "family_member", primary_relationship: "spouse", dob: Date.new(1990, 10, 10), full_name: "member", person: family_person_3) }
    let(:family_member4) { double("family member 4", id: "family_member", primary_relationship: "child", dob: Date.new(1989, 10, 10), full_name: "member", person: family_person_4) }
    let(:family_person_2) { double }
    let(:family_person_3) { double }
    let(:family_person_4) { double }
    let(:coverage_household) { double("coverage household", coverage_household_members: coverage_household_members) }
    let(:coverage_household_members) { [double("coverage household member 2", family_member: family_member2), double("coverage household member 1", family_member: family_member1), double("coverage household member 3", family_member: family_member3), double("coverage household member 4", family_member: family_member4)] }
    let(:hbx_enrollment) { double("hbx enrollment", id: "hbx_id", coverage_kind: "health", effective_on: (TimeKeeper.date_of_record.end_of_month + 1.day), employee_role: employee_role, is_shop?: false) }
    let(:coverage_kind) { hbx_enrollment.coverage_kind }
    let(:current_user) { FactoryBot.create(:user) }
    let(:effective_on) { benefit_group.effective_on_for(employee_role.hired_on) }

    before(:each) do
      assign(:person, person)
      assign(:employee_role, employee_role)
      assign(:benefit_group, benefit_group)
      assign(:coverage_household, coverage_household)
      assign(:market_kind, 'shop')
      assign(:hbx_enrollment, hbx_enrollment)
      assign(:new_effective_on, effective_on)
      assign(:coverage_kind, coverage_kind)
      assign(:adapter, adapter)
      sign_in current_user
      allow(employee_role).to receive(:census_employee).and_return(census_employee)
      allow(family_member1).to receive(:is_primary_applicant?).and_return(true)
      allow(family_member2).to receive(:is_primary_applicant?).and_return(false)
      allow(family_member3).to receive(:is_primary_applicant?).and_return(false)
      allow(family_member4).to receive(:is_primary_applicant?).and_return(false)
      allow(person).to receive(:has_employer_benefits?).and_return(true)
      allow(person).to receive(:active_employee_roles).and_return [employee_role]
      #@eligibility = InsuredEligibleForBenefitRule.new(employee_role,'shop')
      #allow(@eligibility).to receive(:satisfied?).and_return([true, true, false])
      controller.request.path_parameters[:person_id] = person.id
      controller.request.path_parameters[:employee_role_id] = employee_role.id

      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(view).to receive(:policy_helper).and_return(double("Policy", can_access_progress?: true))
      census_employee.benefit_group_assignments.first.benefit_group.plan_year.aasm_state = "enrolling"
    end

    context "when benefit group plan option kind is not solesource", dbclean: :after_each do
      before :each do
        allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
        allow(adapter).to receive(:is_fehb?).with(person).and_return(false)
        allow(adapter).to receive(:can_shop_individual?).with(person).and_return(false)
        allow(adapter).to receive(:can_shop_resident?).with(person).and_return(false)
        allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(false)
        allow(adapter).to receive(:is_eligible_for_dental?).with(employee_role, nil, hbx_enrollment, effective_on).and_return(false)
        allow(adapter).to receive(:shop_health_and_dental_attributes).with(family_member1, employee_role, effective_on, nil).and_return([true, true])
        allow(adapter).to receive(:shop_health_and_dental_attributes).with(family_member2, employee_role, effective_on, nil).and_return([false, true])
        allow(adapter).to receive(:shop_health_and_dental_attributes).with(family_member3, employee_role, effective_on, nil).and_return([true, true])
        allow(adapter).to receive(:shop_health_and_dental_attributes).with(family_member4, employee_role, effective_on, nil).and_return([false, true])
        allow(adapter).to receive(:class_for_ineligible_row).with(family_member1, nil, effective_on, nil).and_return("ineligible_dental_row_#{employee_role.id} is_primary")
        allow(adapter).to receive(:class_for_ineligible_row).with(family_member2, nil, effective_on, nil).and_return("ineligible_health_row_#{employee_role.id} ineligible_dental_row_#{employee_role.id}")
        allow(adapter).to receive(:class_for_ineligible_row).with(family_member3, nil, effective_on, nil).and_return("ineligible_dental_row_#{employee_role.id}")
        allow(adapter).to receive(:class_for_ineligible_row).with(family_member4, nil, effective_on, nil).and_return("ineligible_health_row_#{employee_role.id} ineligible_dental_row_#{employee_role.id}")
        allow(coverage_household).to receive(:valid_coverage_household_members).and_return(coverage_household_members)
        render :template => "insured/group_selection/new.html.erb"
      end

      it "should show the title of family members" do
        expect(rendered).to match /Choose Coverage for your Household/
      end

      if ExchangeTestingConfigurationHelper.dental_market_enabled?
      else
        it "should not display dental option for MA" do
          expect(rendered).to_not have_text("dental")
          expect(rendered).to_not have_selector('#coverage_kind_dental')
        end
      end

      it "should have four checkbox option" do
        expect(rendered).to have_selector("input[type='checkbox']", count: 4)
      end

      it "should have two checked checkbox option and two checked radio button one for benefit_type and other for employer" do
        expect(rendered).to have_selector("input[checked='checked']", count: 4)
      end

      it "should have a disabled checkbox option" do
        expect(rendered).to have_selector("input[disabled='disabled']", count: 2)
      end

      it "should have a readonly checkbox option" do
        # Handled through JS & added cucumber for this
        # expect(rendered).to have_selector("input[readonly='']", count: 1)
      end

      it "should have a 'not eligible'" do
        expect(rendered).to have_selector('td', text: 'Employer sponsored coverage is not available', count: 2)
      end
    end
  end

  if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
    context "coverage selection with incarcerated" do
      let!(:jail_person) { FactoryBot.create(:person, is_incarcerated: true) }
      let!(:individual_market_transition) { FactoryBot.create(:individual_market_transition, person: jail_person)}
      let(:person2) { FactoryBot.create(:person, dob: TimeKeeper.date_of_record - 1.year) }
      let(:person3) { FactoryBot.create(:person, :with_consumer_role) }
      let(:consumer_role) { FactoryBot.create(:consumer_role, person: jail_person, is_incarcerated: 'yes') }
      let(:consumer_role2) { FactoryBot.create(:consumer_role, person: person2, is_incarcerated: 'no', dob: TimeKeeper.date_of_record - 1.year) }
      let(:consumer_role3) { FactoryBot.create(:consumer_role, person: person3, is_incarcerated: 'no') }

      let(:benefit_package) { FactoryBot.build(:benefit_package,
        title: "individual_health_benefits_2015",
        elected_premium_credit_strategy: "unassisted",
        benefit_eligibility_element_group: BenefitEligibilityElementGroup.new(
          market_places:        ["individual"],
          enrollment_periods:   ["open_enrollment", "special_enrollment"],
          family_relationships: BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS,
          benefit_categories:   ["health"],
          incarceration_status: ["unincarcerated"],
          age_range:            0..0,
          citizenship_status:   ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident"],
          residency_status:     ["state_resident"],
          ethnicity:            ["any"]
      ))}
      let(:family) {double}
      let(:family_member1) { instance_double("FamilyMember",id: "family_member", primary_relationship: "self", dob: jail_person.dob, full_name: jail_person.full_name, is_primary_applicant?: true, person: jail_person, family: family) }
      let(:family_member2) { instance_double("FamilyMember",id: "family_member", primary_relationship: "child", dob: person2.dob, full_name: person2.full_name, is_primary_applicant?: false, person: person2, family: family) }
      let(:family_member3) { instance_double("FamilyMember",id: "family_member", primary_relationship: "spouse", dob: person3.dob, full_name: person3.full_name, is_primary_applicant?: false, person: person3, family: family) }

      let(:coverage_household_members) {[double("coverage household member 1", family_member: family_member1), double("coverage household member 2", family_member: family_member2), double("coverage household member 3", family_member: family_member3)]}

      let(:coverage_household_jail) { instance_double("CoverageHousehold", coverage_household_members: coverage_household_members) }
      let(:benefit_sponsorship) {double("benefit sponsorship", earliest_effective_date: TimeKeeper.date_of_record.beginning_of_year)}
      let(:current_hbx) {double("current hbx", benefit_sponsorship: benefit_sponsorship, under_open_enrollment?: true)}
      let(:current_user) {FactoryBot.create(:user)}
      before(:each) do
        assign(:person, jail_person)
        assign(:coverage_household, coverage_household_jail)
        assign(:benefit, benefit_package)
        assign(:adapter, adapter)
        allow(adapter).to receive(:can_shop_shop?).with(jail_person).and_return(false)
        allow(adapter).to receive(:can_shop_both_markets?).with(jail_person).and_return(false)
        allow(adapter).to receive(:can_shop_resident?).with(jail_person).and_return(false)
        allow(adapter).to receive(:can_shop_individual?).with(jail_person).and_return(true)
        allow(adapter).to receive(:class_for_ineligible_row).and_return("ineligible_ivl_row")
        allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx)
        allow_any_instance_of(InsuredEligibleForBenefitRule).to receive(:is_family_relationships_satisfied?).and_return(true)
        allow(benefit_package).to receive(:start_on).and_return(TimeKeeper.date_of_record.beginning_of_year)
        controller.request.path_parameters[:person_id] = jail_person.id
        controller.request.path_parameters[:consumer_role_id] = consumer_role.id
        allow(view).to receive(:shop_health_and_dental_attributes).and_return(false, false, false, true)
        allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
        allow(view).to receive(:policy_helper).and_return(double("Policy", can_access_progress?: true))
        allow(view).to receive(:can_employee_shop?).and_return(false)
        allow(consumer_role).to receive(:latest_active_tax_household_with_year).and_return nil
        allow(consumer_role2).to receive(:latest_active_tax_household_with_year).and_return nil
        allow(consumer_role3).to receive(:latest_active_tax_household_with_year).and_return nil
        allow(person2).to receive(:current_individual_market_transition).and_return(individual_market_transition)
        allow(person3).to receive(:current_individual_market_transition).and_return(individual_market_transition)
        allow(individual_market_transition).to receive(:role_type).and_return('consumer')
        allow(person2).to receive(:is_consumer_role_active?).and_return(true)
        allow(person2).to receive(:is_resident_role_active?).and_return(false)
        allow(person3).to receive(:is_consumer_role_active?).and_return(true)
        allow(person3).to receive(:is_resident_role_active?).and_return(false)
        allow(coverage_household_jail).to receive(:valid_coverage_household_members).and_return(coverage_household_members)
        sign_in current_user
      end

      context "base area" do
        before do
          fm_hash = {}
          rule1 = InsuredEligibleForBenefitRule.new(consumer_role, benefit_package, {family: family, coverage_kind: "health", new_effective_on: TimeKeeper.date_of_record, market_kind: "individual"})
          fm_hash[family_member1.id] = [false, rule1, nil]
          rule2 = InsuredEligibleForBenefitRule.new(consumer_role2, benefit_package, {family: family, coverage_kind: "health", new_effective_on: TimeKeeper.date_of_record, market_kind: "individual"})
          fm_hash[family_member2.id] = [false, rule2, nil]
          rule3 = InsuredEligibleForBenefitRule.new(consumer_role3, benefit_package, {family: family, coverage_kind: "health", new_effective_on: TimeKeeper.date_of_record, market_kind: "individual"})
          fm_hash[family_member1.id] = [false, rule3, nil]
          assign(:fm_hash, fm_hash)
          render :template => "insured/group_selection/new.html.erb"
        end

        it "should show the title of family members" do
          expect(rendered).to match /Choose Coverage for your Household/
        end

        it "should have three checkbox option" do
          expect(rendered).to have_selector("input[type='checkbox']", count: 3)
        end

        it "should have one ineligible row" do
          expect(rendered).to have_selector("tr[class^='ineligible_ivl_row']")
        end

        it "should have coverage_kinds area" do
          expect(rendered).to match /Benefit Type/
        end

        it "should have health radio button" do
          expect(rendered).to have_selector('input[value="health"]')
          expect(rendered).to have_selector('label', text: 'Health')
        end

        it "should have dental radio button when has consumer_role" do
          expect(rendered).to have_selector('input[value="dental"]')
          expect(rendered).to have_selector('label', text: 'Dental')
        end
      end

      # it "should not have dental radio button" do
      #   allow(jail_person).to receive(:has_active_employee_role?).and_return true
      #   allow(jail_person).to receive(:has_active_consumer_role?).and_return false
      #   render :template => "insured/group_selection/new.html.erb"
      # end

      it "should have an incarceration warning with more text" do
        # expect(rendered).to match /Other family members may still be eligible to enroll/
      end

      it "should match the pronoun in the text" do
        # expect(rendered).to match /, she is not eligible/
      end

    end
  end

  context "family member" do
    def new_benefit_group
      instance_double(
        "BenefitGroup",
        relationship_benefits: new_relationship_benefit
      )
    end

    def new_relationship_benefit
      random_value=rand(999_999_999)
      double(
        "RelationshipBenefit",
        offered: "offered:#{random_value}",
        select: double(map: "test")
      )
    end

    def new_family_member
      random_value=rand(999_999_999)
      instance_double(
        "FamilyMember",
        id: "id_#{random_value}",
        dob: 25.years.ago,
        full_name: "full_name_#{random_value}",
        is_primary_applicant?: true,
        primary_relationship: "self",
        person:  FactoryBot.create(:person, is_incarcerated: false, us_citizen: true)
      )
    end

    def new_family_member_1
      random_value=rand(999_999_999)
      instance_double(
        "FamilyMember",
        id: "id_#{random_value}",
        dob: 3.years.ago,
        full_name: "full_name_#{random_value}",
        is_primary_applicant?: false,
        primary_relationship: "child",
        person:  FactoryBot.create(:person, is_incarcerated: false, us_citizen: true)
      )
    end

    let(:family_members){[new_family_member, new_family_member_1]}
    let(:person) { instance_double("Person", id: "Person.id") }
    # let(:coverage_household) { instance_double("CoverageHousehold", family_members: family_members) }
    let(:coverage_household_members) {[double("new coverage household member", family_member: new_family_member), double("new coverage household member 1", family_member: new_family_member_1)]}
    let(:coverage_household) { instance_double("CoverageHousehold", coverage_household_members: coverage_household_members) }
    let(:employee_role) { instance_double("EmployeeRole", id: "EmployeeRole.id", benefit_group: new_benefit_group, person: person) }
    let(:hbx_enrollment) {HbxEnrollment.new}
    let(:employer_profile) { FactoryBot.build(:employer_profile) }
    let(:effective_on) { benefit_group.effective_on_for(employee_role.hired_on) }


    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :coverage_household, coverage_household
      assign :eligibility, instance_double("InsuredEligibleForBenefitRule", :satisfied? => true)
      assign :hbx_enrollment, hbx_enrollment
      assign :adapter, adapter
      allow(person).to receive(:has_active_employee_role?).and_return(false)
      allow(person).to receive(:has_employer_benefits?).and_return(false)
      allow(person).to receive(:active_employee_roles).and_return []
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(true)
      allow(employee_role).to receive(:employer_profile).and_return(employer_profile)
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.end_of_month + 1.day)
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(view).to receive(:can_employee_shop?).and_return(false)
      allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
      allow(adapter).to receive(:can_shop_both_markets?).and_return(false)
      render file: "insured/group_selection/new.html.erb"
    end

    # it "should display family members" do
    #   family_members.each do |member|
    #     expect(rendered).to match(/#{member.full_name}/m)
    #   end
    # end
  end

  context "family member with no benefit group" do
    def new_family_member
      random_value=rand(999_999_999)
      instance_double(
        "FamilyMember",
        id: "id_#{random_value}",
        dob: 25.years.ago,
        full_name: "full_name_#{random_value}",
        is_primary_applicant?: true,
        primary_relationship: "self",
        person:  FactoryBot.create(:person, is_incarcerated: false, us_citizen: true)
      )
    end

    def new_family_member_1
      random_value=rand(999_999_999)
      instance_double(
        "FamilyMember",
        id: "id_#{random_value}",
        dob: 3.years.ago,
        full_name: "full_name_#{random_value}",
        is_primary_applicant?: false,
        primary_relationship: "child",
        person:  FactoryBot.create(:person, is_incarcerated: false, us_citizen: true)
      )
    end

    let(:family_members){[new_family_member, new_family_member_1]}
    let(:person) { instance_double("Person", id: "Person.id") }
    let(:coverage_household_members) {[double("new coverage household member", family_member: new_family_member), double("new coverage household member 1", family_member: new_family_member_1)]}
    let(:coverage_household) { double("coverage household", coverage_household_members: coverage_household_members) }
    let(:employer_profile) {FactoryBot.build(:employer_profile)}
    let(:employee_role) { instance_double("EmployeeRole", id: "EmployeeRole.id", benefit_group: nil, employer_profile: employer_profile, person: person) }
    let(:hbx_enrollment) {double("hbx enrollment", id: "hbx_id", effective_on: (TimeKeeper.date_of_record.end_of_month + 1.day), employee_role: employee_role, benefit_group: nil)}

    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :coverage_household, coverage_household
      assign :eligibility, instance_double("InsuredEligibleForBenefitRule", :satisfied? => true)
      assign :hbx_enrollment, hbx_enrollment
      assign :adapter, adapter
      allow(person).to receive(:has_active_employee_role?).and_return(false)
      allow(person).to receive(:has_employer_benefits?).and_return(false)
      allow(person).to receive(:active_employee_roles).and_return []
      allow(view).to receive(:can_employee_shop?).and_return(false)
      allow(employee_role).to receive(:is_under_open_enrollment?).and_return(false)
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
      allow(adapter).to receive(:can_shop_both_markets?).and_return(false)
      allow(adapter).to receive(:shop_health_and_dental_attributes).and_return([true, false, false, false])
      allow(adapter).to receive(:can_shop_individual?).and_return(false)
      allow(adapter).to receive(:can_shop_resident?).and_return(false)
      allow(adapter).to receive(:class_for_ineligible_row).and_return("ineligible_dental_row_#{employee_role.id} is_primary")
      # allow(adapter).to receive(:class_for_ineligible_row).with(new_family_member_1, nil, nil).and_return("ineligible_health_row_#{employee_role.id} ineligible_dental_row_#{employee_role.id}")
      render file: "insured/group_selection/new.html.erb"
    end

    # it "should display family members" do
    #   family_members.each do |member|
    #     expect(rendered).to match(/#{member.full_name}/m)
    #   end
    # end
  end

  context "change plan", dbclean: :after_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"
    let(:person) { FactoryBot.create(:person, :with_employee_role) }
    let(:employee_role) { FactoryBot.build_stubbed(:employee_role) }
    let(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package ) }
    let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
    let(:benefit_group) { current_benefit_package }
    let(:coverage_household) { double("coverage household", coverage_household_members: []) }
    let(:hbx_enrollment) {double("hbx enrollment", coverage_selected?: true, id: "hbx_id", effective_on: (TimeKeeper.date_of_record.end_of_month + 1.day), employee_role: employee_role, benefit_group: benefit_group, is_shop?: true)}
    let(:employer_profile) { benefit_sponsorship.profile }
    let(:current_user) { FactoryBot.create(:user) }
    let(:effective_on_date) { TimeKeeper.date_of_record.beginning_of_month }

    before :each do
      allow(employee_role).to receive(:census_employee).and_return(census_employee)
      assign :person, person
      assign :employee_role, employee_role
      assign :coverage_household, coverage_household
      assign :market_kind, 'shop'
      assign :change_plan, true
      assign :hbx_enrollment, hbx_enrollment
      assign :effective_on_date, effective_on_date
      assign(:adapter, adapter)
      allow(person).to receive(:has_active_employee_role?).and_return(true)
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.beginning_of_month)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(view).to receive(:is_under_open_enrollment?).and_return(true)
      allow(view).to receive(:can_employee_shop?).and_return(false)
      allow(view).to receive(:dental_relationship_benefits).with(benefit_group).and_return ["employee"]
      allow(employee_role).to receive(:employer_profile).and_return(employer_profile)
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
      allow(adapter).to receive(:is_fehb?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_resident?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_individual?).with(person).and_return(false)
      allow(adapter).to receive(:is_eligible_for_dental?).with(employee_role, true, hbx_enrollment, effective_on_date).and_return(true)
      allow(coverage_household).to receive(:valid_coverage_household_members).and_return([])
      sign_in current_user
    end

    it "should display title" do
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to match(/What would you like to do/)
    end

    it "should show shop for new plan submit" do
      allow(benefit_group).to receive(:plan_option_kind).and_return("metal_level")
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[value='Shop for new plan']")
    end

    it "should not show shop for new plan submit when single_plan" do
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")

      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[value='Shop for new plan']", count: 1)
    end

    it "when hbx_enrollment not terminated" do
      allow(view).to receive(:show_keep_existing_plan).and_return true
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[value='Keep existing plan']", count: 1)
      expect(rendered).to have_selector("a", text: "Select Plan to Terminate",  count: 1)
    end

    it "when hbx_enrollment not terminated and not shop_for_plans" do
      assign(:shop_for_plans, "shop_for_plans")
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[value='Keep existing plan']", count: 1)
      expect(rendered).to have_selector("a", text: "Select Plan to Terminate",  count: 1)
    end

    it "when hbx_enrollment is terminated" do
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(false)
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[value='Keep existing plan']", count: 0)
    end

    it "should have back to my account link" do
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("a[href='/families/home']", text: 'Back To My Account')
    end

    if dental_market_enabled?
      it "should see dental radio option" do
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).to have_selector('#coverage_kind_dental')
      end
    end

    it "should see health radio option" do
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector('#coverage_kind_health')
    end

    it "shouldn't see marketplace options" do
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to_not have_selector('h3', text: 'Marketplace')
    end

    it "should display effective on date" do
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to match(/EFFECTIVE DATE/i)
    end
  end

  context "waive plan" do
    let(:person) { employee_role.person }
    let(:employee_role) { FactoryBot.create(:employee_role) }
    let(:benefit_group) { FactoryBot.create(:benefit_group) }

    let(:hbx_enrollment) {HbxEnrollment.new}
    let(:coverage_household) { double("coverage household", coverage_household_members: []) }

    before :each do
      allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
      assign :person, person
      assign :employee_role, employee_role
      assign :coverage_household, coverage_household
      assign :market_kind, 'shop'
      assign :change_plan, true
      assign :hbx_enrollment, hbx_enrollment
      assign :adapter, adapter
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.beginning_of_month)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:employee_role).and_return(nil)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(view).to receive(:can_employee_shop?).and_return(false)
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
      allow(adapter).to receive(:is_fehb?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_both_markets?).and_return(false)
      allow(adapter).to receive(:can_shop_resident?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_individual?).with(person).and_return(false)
      allow(adapter).to receive(:is_eligible_for_dental?).and_return(true)
      allow(coverage_household).to receive(:valid_coverage_household_members).and_return([])
    end

    it "should have the waive confirmation modal" do
      render file: "insured/group_selection/new.html.erb"
      expect(view).to render_template(:partial => "ui-components/v1/modals/_waive_confirmation", :count => 1)
    end
  end

  context "market_kind" do
    let(:person) { FactoryBot.create(:person) }
    let(:employee_role) { FactoryBot.create(:employee_role) }
    let(:benefit_group) { FactoryBot.create(:benefit_group) }
    let(:coverage_household) { double("coverage household", coverage_household_members: []) }
    let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }
    let(:hbx_enrollment) {double("hbx enrollment", coverage_selected?: true, id: "hbx_id", effective_on: effective_on, employee_role: employee_role, benefit_group: benefit_group, is_shop?: false)}

    before :each do
      allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
      assign :person, person
      assign :employee_role, employee_role
      assign :coverage_household, coverage_household
      assign :change_plan, true
      assign :hbx_enrollment, hbx_enrollment
      assign :adapter, adapter
      assign :change_plan, true
      assign :new_effective_on, effective_on
      allow(hbx_enrollment).to receive(:effective_on).and_return(effective_on)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(view).to receive(:can_employee_shop?).and_return(false)
      allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
      allow(adapter).to receive(:is_fehb?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_both_markets?).and_return(false)
      allow(adapter).to receive(:can_shop_resident?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_individual?).with(person).and_return(false)
      allow(adapter).to receive(:is_eligible_for_dental?).with(employee_role, true, hbx_enrollment, effective_on).and_return(true)
      allow(coverage_household).to receive(:valid_coverage_household_members).and_return([])

    end

    it "when present" do
      assign :market_kind, "shop"
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).to have_selector("input[type='hidden']", visible: false)
      expect(rendered).to have_selector("input[value='shop']", visible: false)
    end

    context "when blank" do
      before :each do
        assign :market_kind, ""
        render file: "insured/group_selection/new.html.erb"
      end

      # it "should have title" do
      #   expect(rendered).to match /Market Kind/
      # end
      #
      # it "should have options" do
      #   Plan::MARKET_KINDS.each do |kind|
      #     expect(rendered).to have_selector("input[value='#{kind}']")
      #   end
      # end
    end
  end

  if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
    context "change plan with consumer role" do
      let(:person) { FactoryBot.create(:person, :with_consumer_role) }
      let!(:individual_market_transition) { FactoryBot.create(:individual_market_transition, person: person)}
      let(:employee_role) { FactoryBot.create(:employee_role) }
      let(:benefit_group) { FactoryBot.create(:benefit_group) }
      let(:coverage_household) { double("coverage household", coverage_household_members: []) }
      let(:hbx_enrollment) {double("hbx enrollment", coverage_selected?: true, id: "hbx_id", effective_on: (TimeKeeper.date_of_record.end_of_month + 1.day), employee_role: employee_role, benefit_group: benefit_group, is_shop?: false)}

      before :each do
        allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
        assign :person, person
        assign :employee_role, employee_role
        assign :coverage_household, coverage_household
        assign :market_kind, 'individual'
        assign :change_plan, true
        assign :hbx_enrollment, hbx_enrollment
        assign(:adapter, adapter)
        allow(adapter).to receive(:can_shop_shop?).with(person).and_return(false)
        allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(false)
        allow(adapter).to receive(:can_shop_resident?).with(person).and_return(false)
        allow(adapter).to receive(:can_shop_individual?).with(person).and_return(true)
        allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.beginning_of_month)
        allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
        allow(view).to receive(:can_employee_shop?).and_return(false)
        allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(true)
        allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
        allow(coverage_household).to receive(:valid_coverage_household_members).and_return([])
      end

      it "shouldn't see dental radio option" do
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).to have_selector('#coverage_kind_dental')
      end

      it "should see health radio option" do
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).to have_selector('#coverage_kind_health')
      end

      it "shouldn't see marketplace options" do
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).to have_selector('h3', text: 'Marketplace')
      end

      it "shouldn't see terminate plan" do
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).to_not have_selector("a", text: "Select Plan to Terminate")
      end
    end
  end

  context "change plan with ee role" do
    let(:person) { FactoryBot.create(:person, :with_employee_role) }
    let(:employee_role) { FactoryBot.create(:employee_role) }
    let(:benefit_group) { FactoryBot.create(:benefit_group) }
    let(:coverage_household) { double("coverage household", coverage_household_members: []) }
    let(:effective_on) { TimeKeeper.date_of_record.end_of_month + 1.day }
    let(:hbx_enrollment) {double("hbx enrollment", coverage_selected?: true, id: "hbx_id", effective_on: effective_on, employee_role: employee_role, benefit_group: benefit_group, is_shop?: false)}

    before :each do
      allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
      assign :person, person
      assign :employee_role, employee_role
      assign :coverage_household, coverage_household
      assign :market_kind, 'shop'
      assign :change_plan, nil
      assign :hbx_enrollment, hbx_enrollment
      assign :new_effective_on, effective_on
      assign(:adapter, adapter)
      allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.beginning_of_month)
      allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
      allow(view).to receive(:can_employee_shop?).and_return(false)
      allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(true)
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(view).to receive(:policy_helper).and_return(double("Policy", can_access_progress?: true))
      allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
      allow(adapter).to receive(:is_fehb?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_both_markets?).and_return(false)
      allow(adapter).to receive(:can_shop_resident?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_individual?).with(person).and_return(false)
      allow(adapter).to receive(:is_eligible_for_dental?).with(employee_role, nil, hbx_enrollment, effective_on).and_return(true)
      allow(coverage_household).to receive(:valid_coverage_household_members).and_return([])
    end

    it "shouldn't see waiver button" do
      render file: "insured/group_selection/new.html.erb"
      expect(rendered).not_to have_text('Waiver Coverage')
    end
  end

  context "#can_shop_shop?", dbclean: :after_each do
    let(:census_employee) { double("CensusEmployee", id: 'ce_id', employer_profile: double("EmployerProfile", legal_name: "acme, Inc"))}
    let(:person) { FactoryBot.create(:person) }
    let(:enrollment) { double("HbxEnrollment", id: 'enr_id', employee_role: nil, benefit_group: benefit_group)}
    let(:employee_role) { double("EmployeeRole", id: 'er_id', person: person, census_employee: census_employee)}
    let(:benefit_group) { FactoryBot.create(:benefit_group) }
    let(:coverage_household) { double("coverage household", coverage_household_members: []) }

    before do
      assign(:person, person)
      assign(:hbx_enrollment, enrollment)
      assign(:employee_role, employee_role)
      assign :coverage_household, coverage_household
      assign(:benefit_group, benefit_group)
      assign(:adapter, adapter)
      allow(view).to receive(:can_shop_shop?).with(person).and_return true
      allow(view).to receive(:health_relationship_benefits).with(benefit_group).and_return ["employee"]
      allow(view).to receive(:dental_relationship_benefits).with(benefit_group).and_return ["employee"]
      allow(view).to receive(:can_employee_shop?).and_return(false)
      allow(person).to receive(:active_employee_roles).and_return [employee_role]
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      allow(view).to receive(:policy_helper).and_return(double("Policy", can_access_progress?: true))
      allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
      allow(adapter).to receive(:is_fehb?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_resident?).with(person).and_return(false)
      allow(adapter).to receive(:can_shop_individual?).with(person).and_return(false)
      allow(adapter).to receive(:is_eligible_for_dental?).and_return(false)
      allow(coverage_household).to receive(:valid_coverage_household_members).and_return([])
    end

    # Loading coverage household member records only once & displaying errors based on selection

    it "should render coverage_household partial to display chm's" do
      render file: "insured/group_selection/new.html.erb"
      expect(response).to render_template(:partial => 'coverage_household', :locals => {:coverage_household => nil})
    end
  end


  if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
    context "change plan with both roles" do
      let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_employee_role) }
      let!(:individual_market_transition) { FactoryBot.create(:individual_market_transition, person: person)}
      let(:employee_role) { FactoryBot.build_stubbed(:employee_role) }
      let(:census_employee) { FactoryBot.build_stubbed(:census_employee, benefit_group_assignments: [benefit_group_assignment]) }
      let(:benefit_group_assignment) { FactoryBot.build_stubbed(:benefit_group_assignment, benefit_group: benefit_group) }
      let(:benefit_group) { FactoryBot.create(:benefit_group, :with_valid_dental, dental_reference_plan_id: "9182391823912", elected_dental_plan_ids: ['12313213','123132321']) }
      let(:coverage_household) { double("coverage household", coverage_household_members: []) }
      let(:hbx_enrollment) do
        double(
          'hbx enrollment',
          coverage_selected?: true,
          id: 'hbx_id',
          kind: 'individual',
          effective_on: (TimeKeeper.date_of_record.end_of_month + 1.day),
          employee_role: employee_role,
          benefit_group: benefit_group,
          is_shop?: false
        )
      end

      let(:adapter) { instance_double(GroupSelectionPrevaricationAdapter) }

      before :each do
        allow(person).to receive(:has_active_employee_role?).and_return(true)
        allow(person).to receive(:has_employer_benefits?).and_return(true)
        allow(employee_role).to receive(:census_employee).and_return(census_employee)
        assign :person, person
        assign :employee_role, employee_role
        assign :coverage_household, coverage_household
        assign :market_kind, 'individual'
        assign :change_plan, true
        assign :benefit_group, benefit_group
        assign :hbx_enrollment, hbx_enrollment
        assign(:adapter, adapter)
        allow(adapter).to receive(:can_shop_individual?).with(person).and_return(true)
        allow(adapter).to receive(:is_eligible_for_dental?).and_return(false)
        allow(hbx_enrollment).to receive(:effective_on).and_return(TimeKeeper.date_of_record.beginning_of_month)
        allow(hbx_enrollment).to receive(:coverage_selected?).and_return(true)
        allow(hbx_enrollment).to receive(:may_terminate_coverage?).and_return(true)
        allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
        allow(view).to receive(:can_employee_shop?).and_return(false)
        allow(coverage_household).to receive(:valid_coverage_household_members).and_return([])
      end

      it "should see dental radio option" do
        allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
        allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(true)
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).to have_selector('#coverage_kind_dental')
      end

      it "should see health radio option" do
        allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
        allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(true)
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).to have_selector('#coverage_kind_health')
      end

      it "should see employer-sponsored coverage radio option" do
        allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
        allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(true)
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).to have_selector('#market_kind_shop')
      end

      it "should see individual coverage radio option" do
        allow(adapter).to receive(:can_shop_shop?).with(person).and_return(true)
        allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(true)
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).to have_selector('#market_kind_individual')
      end

      it "should see marketplace options" do
        allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(false)
        allow(adapter).to receive(:can_shop_shop?).with(person).and_return(false)
        allow(adapter).to receive(:can_shop_resident?).with(person).and_return(false)
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).to have_selector('h3', text: 'Marketplace')
      end

      it "should not see employer-sponsored coverage radio option" do
        allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(false)
        allow(adapter).to receive(:can_shop_shop?).with(person).and_return(false)
        allow(adapter).to receive(:can_shop_resident?).with(person).and_return(false)
        allow(person).to receive(:has_employer_benefits?).and_return(false)
        render file: "insured/group_selection/new.html.erb"
        expect(rendered).not_to have_selector('#market_kind_shop')
      end

      context "consumer with both roles but employee isn't offering dental" do
        let(:benefit_group_no_dental) { FactoryBot.create(:benefit_group, dental_reference_plan_id: '', elected_dental_plan_ids: []) }
        let(:employee_role) { FactoryBot.build_stubbed(:employee_role) }
        let(:census_employee) { FactoryBot.build_stubbed(:census_employee, benefit_group_assignments: [benefit_group_assignment]) }
        let(:benefit_group_assignment) { FactoryBot.build_stubbed(:benefit_group_assignment, benefit_group: benefit_group_no_dental) }

        before(:each) do
          allow(adapter).to receive(:can_shop_shop?).and_return(true)
          allow(adapter).to receive(:can_shop_both_markets?).with(person).and_return(true)
        end

        it "dental option should have a class of dn" do
          allow(adapter).to receive(:is_eligible_for_dental?).and_return(false)
          assign(:market_kind, 'shop')
          render file: "insured/group_selection/new.html.erb"
          expect(rendered).to have_selector('.n-radio-row.dn')
        end

        it "dental option should not be visible" do
          allow(adapter).to receive(:is_eligible_for_dental?).and_return(true)
          render file: "insured/group_selection/new.html.erb"
          expect(rendered).to_not have_selector('.n-radio-row.dn')
        end
      end
    end
  end
end
