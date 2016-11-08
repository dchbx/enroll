require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_home_tab.html.erb" do
  context "employer profile dashboard with current plan year" do

    let(:start_on){TimeKeeper.date_of_record.beginning_of_year}
    let(:end_on){TimeKeeper.date_of_record.end_of_year}
    let(:end_on_negative){ TimeKeeper.date_of_record.beginning_of_year - 2.years }


    def new_organization
      instance_double(
        "Organization",
        office_locations: new_office_locations
      )
    end

    def office_location
      random_value = rand(999_999_999)
      instance_double(
        "OfficeLocation",
        address: new_address(random_value),
        phone: new_phone(random_value),
        )
    end

    def new_address(random_value)
      double(
        "Address",
        kind: "test#{random_value}",
        to_html: "test"
        )
    end

    def new_phone(random_value)
      double(
        "Phone",
        kind: "test#{random_value}"
        )
    end

    def broker_agency_account
      instance_double(
        "BrokerAgencyAccount",
        is_active: true,
        writing_agent: broker_role
        )
    end

    def employer_profile
      instance_double(
        "EmployerProfile",
        legal_name: "My silly name",
        organization: new_organization,
        fein: "098111000",
        entity_kind: "my entity kind",
        broker_agency_profile: new_broker_agency_profile,
        published_plan_year: plan_year
        )
    end

    def new_broker_agency_profile
      instance_double(
        "BrokerAgencyProfile",
        legal_name: "my broker legal name",
        primary_broker_role: broker_role
        )
    end

    def carrier_profile
      random_value = rand(999_999_999)
      double(
        "CarrierProfile",
        legal_name: "legal_name#{random_value}"
        )
    end

    def reference_plan_1
      double(
        "Plan",
        name: "name_1",
        plan_type: "ppo",
        metal_level: "metal_level_1",
        carrier_profile: carrier_profile,
        coverage_kind: 'health',
        active_year: TimeKeeper.date_of_record.beginning_of_year,
        dental_level: 'high'
        )
    end

    def reference_plan_2
      double(
        "Plan",
        name: "name_2",
        plan_type: "",
        metal_level: "metal_level_2",
        carrier_profile: carrier_profile,
        coverage_kind: 'dental',
        active_year: TimeKeeper.date_of_record.beginning_of_year,
        dental_level: 'high'
        )
    end

    def benefit_group_1
      double(
        "BenefitGroup",
        title: "title_1",
        effective_on_kind: "first_of_month",
        effective_on_offset: "30",
        plan_option_kind: "plan_option_kind_1",
        description: "my first benefit group",
        relationship_benefits: [relationship_benefits],
        reference_plan: reference_plan_1,
        reference_plan_id: double("id"),
        dental_reference_plan: reference_plan_1,
        dental_reference_plan_id: "498523982893",
        monthly_employer_contribution_amount: "monthly_employer_contribution_amount_1",
        monthly_min_employee_cost: "monthly_min_employee_cost_1",
        monthly_max_employee_cost: "monthly_max_employee_cost_1",
        id: "9813829831293",
        dental_plan_option_kind: "single_plan",
        elected_dental_plan_ids: [],
        elected_dental_plans: [],
        dental_relationship_benefits: [relationship_benefits],
        )
    end

    def benefit_group_2
      double(
        "BenefitGroup",
        title: "title_2",
        effective_on_kind: "date_of_hire",
        effective_on_offset: "0",
        plan_option_kind: "plan_option_kind_2",
        description: "my first benefit group",
        relationship_benefits: [relationship_benefits],
        reference_plan: reference_plan_2,
        reference_plan_id: double("id"),
        dental_reference_plan: reference_plan_2,
        dental_reference_plan_id: "498523982893",
        monthly_employer_contribution_amount: "monthly_employer_contribution_amount_2",
        monthly_min_employee_cost: "monthly_min_employee_cost_2",
        monthly_max_employee_cost: "monthly_max_employee_cost_2",
        id: "9456349532",
        dental_plan_option_kind: "single_plan",
        elected_dental_plan_ids: [],
        elected_dental_plans: [],
        dental_relationship_benefits: [relationship_benefits],

        )
    end

    def relationship_benefits
      random_value = rand(999_999_999)
      double(
        "RelationshipBenefit",
        offered: "offered;#{random_value}",
        relationship: "relationship;#{random_value}",
        premium_pct: "premium_pct;#{random_value}"
        )
    end

    def plan_year
      instance_double(
        "PlanYear",
        start_on: start_on,
        end_on: end_on,
        open_enrollment_start_on: PlanYear.calculate_open_enrollment_date(start_on)[:open_enrollment_start_on],
        open_enrollment_end_on: PlanYear.calculate_open_enrollment_date(start_on)[:open_enrollment_end_on],
        eligible_to_enroll_count: 4,
        covered_count: 4,
        waived_count: 4,
        total_enrolled_count: 10,
        employee_participation_percent: 40,
        non_business_owner_enrolled: 10.times.map{|i| double },
        hbx_enrollments: [hbx_enrollment],
        additional_required_participants_count: 5,
        benefit_groups: benefit_groups,
        aasm_state: 'draft',
        employer_profile: double(census_employees: double(count: 10))
        )
    end

    def broker_role
      instance_double(
        "BrokerRole",
        person: new_person,
        npn: 7232323
        )
    end

    def new_person
      random_value = rand(999_999_999)
      instance_double(
        "Person",
        full_name: "my full name",
        phones: [new_phone(random_value)],
        emails: [new_email]
        )
    end

    def new_email
      instance_double(
        "Email",
        address: "test@example.com"
        )
    end

    def hbx_enrollment
      instance_double(
        "HbxEnrollment",
        total_premium: double("total_premium"),
        total_employer_contribution: double("total_employer_contribution"),
        total_employee_cost: double("total_employee_cost")
        )
    end

    let(:new_office_locations){[office_location,office_location]}
    let(:current_plan_year){employer_profile.published_plan_year}
    let(:benefit_groups){ [benefit_group_1, benefit_group_2] }

    before :each do
      allow(view).to receive(:pundit_class).and_return(double("EmployerProfilePolicy", updateable?: true))
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true))

      assign :employer_profile, employer_profile
      assign :hbx_enrollments, [hbx_enrollment]
      assign :current_plan_year, employer_profile.published_plan_year
      assign :participation_minimum, 0
      assign :broker_agency_accounts, [ broker_agency_account ]
      controller.request.path_parameters[:id] = "11111111"
      render partial: "employers/employer_profiles/my_account/home_tab"
    end

    it "should display title" do
      expect(rendered).to have_selector("h1", text: "My Health Benefits Program")
    end

    it "should display benefit groups" do
      current_plan_year.benefit_groups.each do |bg|
        expect(rendered).to match(/.*#{bg.title}.*/mi)
        expect(rendered).to match(/.*#{bg.description}.*/mi)
        expect(rendered).to match(/.*#{bg.reference_plan.plan_type}.*/mi)
      end
    end

    it "should not display minimum participation requirement" do
        assign :end_on, end_on_negative
        expect(rendered).to_not match(/or more needed by/i)
    end

  end

  context "employer profile without current plan year" do
    let(:employer_profile){ FactoryGirl.create(:employer_profile) }

    before :each do
      allow(view).to receive(:pundit_class).and_return(double("EmployerProfilePolicy", updateable?: true))
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true))
      assign :employer_profile, employer_profile
      render partial: "employers/employer_profiles/my_account/home_tab"
    end

    it "should not display employee enrollment information" do
      expect(rendered).to_not match(/Employee Enrollments and Waivers/i)
    end

    it "should display a link to download employer guidance pdf" do
      expect(rendered).to have_selector(".icon-left-download", text: /Download Step-by-Step Instructions/i)
    end

  end
end
