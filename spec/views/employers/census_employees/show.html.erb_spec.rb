require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_product_spec_helpers"

RSpec.describe "employers/census_employees/show.html.erb", dbclean: :after_each do
  let(:effective_period) { (effective_period_start_on..effective_period_end_on) }

  let(:effective_period_start_on) { current_effective_date }
  let(:effective_period_end_on) { effective_period_start_on + 1.year - 1.day }

  let(:current_effective_date)  { (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year }
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  let(:person) {FactoryBot.create(:person)}
  let!(:family){ FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:household){ family.active_household }
  let(:employee_role1) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile) }
  let(:census_employee) do
    FactoryBot.create(
      :census_employee,
      :with_active_assignment,
      benefit_sponsorship: benefit_sponsorship,
      employer_profile: benefit_sponsorship.profile,
      benefit_group: current_benefit_package,
      employee_role_id: employee_role1.id
    )
  end
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id:hbx_enrollment_member.id, product_price:BigDecimal(100),sponsor_contribution:BigDecimal(100))}
  let(:group_enrollment) {BenefitSponsors::Enrollments::GroupEnrollment.new(product: product, member_enrollments:[member_enrollment], product_cost_total:'')}
  let(:address){ Address.new(kind: 'home', address_1: "1111 spalding ct", address_2: "apt 444", city: "atlanta", state: "ga", zip: "30338") }
  let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let(:hbx_enrollment){ FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
    household: household,
    family: family,
    hbx_enrollment_members: [hbx_enrollment_member],
    coverage_kind: "health",
    external_enrollment: false )
  }
  let(:hbx_enrollment_two){ FactoryBot.create(:hbx_enrollment, :with_product,
    household: household,
    family: family,
    hbx_enrollment_members: [hbx_enrollment_member],
    coverage_kind: "dental",
    external_enrollment: false )
  }
  let(:decorated_hbx_enrollment) { double(member_enrollments:[member_enrollment], product_cost_total:'',sponsor_contribution_total:'') }
  let(:user) { FactoryBot.create(:user) }
  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile) }
  let(:benefit_package) { double(is_congress: false) } #FIX ME: remove this when is_congress attribute added to benefit package

  context 'show' do
    before(:each) do
      view.extend BenefitSponsors::Engine.helpers
      sign_in user
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true, list_enrollments?: true))
      assign(:employer_profile, abc_profile)
      assign(:datatable, Effective::Datatables::EmployeeDatatable.new({id: abc_profile.id}))
      assign(:census_employee, census_employee)
      assign(:benefit_group_assignment, benefit_group_assignment)
      assign(:benefit_sponsorship, benefit_sponsorship)
      assign(:hbx_enrollment, hbx_enrollment)
      assign(:hbx_enrollments, [hbx_enrollment])
      assign(:benefit_group, current_benefit_package)
      assign(:product, product)
      assign(:status, "terminated")
      assign(:active_benefit_group_assignment, benefit_group_assignment)
      allow(hbx_enrollment_member).to receive(:person).and_return(person)
      allow(hbx_enrollment_member).to receive(:primary_relationship).and_return("self")
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      allow(hbx_enrollment).to receive(:product).and_return(product)
      allow(hbx_enrollment).to receive(:decorated_hbx_enrollment).and_return(decorated_hbx_enrollment)
      allow(hbx_enrollment).to receive(:composite_rated?).and_return(true)
      allow(hbx_enrollment).to receive(:total_premium).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:total_employer_contribution).and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:total_employee_cost).and_return(hbx_enrollment)
      allow(benefit_group_assignment).to receive(:active_and_waived_enrollments).and_return([hbx_enrollment])
      allow(view).to receive(:policy_helper).and_return(double('EmployerProfile', updateable?: true, list_enrollments?: true))
      allow(SicCodeRatingFactorSet).to receive(:where).and_return([double(lookup: 1.0)])
      allow(EmployerGroupSizeRatingFactorSet).to receive(:where).and_return([double(lookup: 1.0)])
      allow(hbx_enrollment).to receive(:benefit_group).and_return(current_benefit_package)
      allow(group_enrollment).to receive(:member_enrollments).and_return([member_enrollment])
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_package)
    end

    it "should show the address of census employee" do
      allow(census_employee).to receive(:address).and_return(address)
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to match(/#{address.address_1}/)
      expect(rendered).to match(/#{address.address_2}/)
      expect(rendered).to match(/#{address.city}/)
      expect(rendered).to match(/#{address.state}/i)
      expect(rendered).to match(/#{address.zip}/)
    end

    it "should show the address feild of census employee if address not present" do
      allow(census_employee).to receive(:address).and_return([])
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to match(/Address/)
      expect(rendered).to match(/ADDRESS LINE 2/)
      expect(rendered).to match(/ADDRESS LINE 1/)
      expect(rendered).to match(/CITY/)
      expect(rendered).to match(/SELECT STATE/)
      expect(rendered).to match(/ZIP/)
      expect(rendered).to match(/Add Dependent/i)
    end

    it "should not show the plan" do
      allow(benefit_group_assignment).to receive(:active_and_waived_enrollments).and_return([])
      assign(:hbx_enrollments, [])
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to_not match(/Plan/)
      expect(rendered).to_not have_selector('p', text: 'Benefit Group: plan name')
    end

    it "should show waiver" do
      hbx_enrollment.update_attributes(:aasm_state => 'inactive')
      allow(census_employee).to receive(:enrollments_for_display).and_return([hbx_enrollment])
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
      allow(view).to receive(:disable_make_changes_button?).with(hbx_enrollment).and_return true
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to match(/Waived Date/i)
      expect(rendered).to match(/#{hbx_enrollment.waiver_reason}/)
    end

    it "should show plan name" do
      allow(census_employee).to receive(:enrollments_for_display).and_return([hbx_enrollment])
      allow(hbx_enrollment).to receive(:benefit_group).and_return nil
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to match(/#{hbx_enrollment.product.name}/)
    end

    it "should show plan cost" do
      allow(census_employee).to receive(:enrollments_for_display).and_return([hbx_enrollment])
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to match(/Employer Contribution/)
      expect(rendered).to match(/You Pay/)
    end

    it "should not show the health enrollment if it is external" do
      hbx_enrollment.update_attributes!(:external_enrollment => true)
      assign(:hbx_enrollments, HbxEnrollment.enrollments_for_display_census_employee_show(census_employee))
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to_not match(/Plan/)
      expect(rendered).to_not have_selector('p', text: 'Benefit Group: plan name')
    end

    it "should not show the dental enrollment if it is external" do
      hbx_enrollment_two.update_attributes!(:external_enrollment => true)
      assign(:hbx_enrollments, HbxEnrollment.enrollments_for_display_census_employee_show(census_employee))
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to_not match(/Plan/)
      expect(rendered).to_not have_selector('p', text: 'Benefit Group: plan name')
    end

    context 'drop down menu at different cases' do
      it "should have BENEFIT PACKAGE and benefit plan" do
        render template: "employers/census_employees/show.html.erb"
        expect(rendered).to have_selector('div', text: 'SELECT BENEFIT PACKAGE')
        expect(rendered).to have_selector('div', text: current_benefit_package.title)
      end
    end

    context "when both ee and er have no benefit group assignment" do

      before do
        assign(:benefit_sponsorship, benefit_sponsorship)
      end

      it "should only have BENIFIT PACKAGE" do
        render template: "employers/census_employees/show.html.erb"
        expect(rendered).to have_selector('div', text: 'SELECT BENEFIT PACKAGE')
      end
    end

    context 'with no email linked with census employee' do
      it "should create a blank email record if there was no email for census employees" do
        census_employee = FactoryBot.create(:census_employee, :blank_email)
        render template: "employers/census_employees/show.html.erb"
        expect(census_employee.email).to eq nil
      end

      it "should return the existing one if email was already present" do
        census_employee = FactoryBot.create(:census_employee)
        address = census_employee.email.address
        render template: "employers/census_employees/show.html.erb"
        expect(census_employee.email.kind).to eq 'home'
        expect(census_employee.email.address).to eq address
      end
    end

    context 'with a previous coverage waiver' do
      let(:hbx_enrollment_three) do
        FactoryBot.create(
          :hbx_enrollment,
          :with_product,
          household: household,
          family: family,
          benefit_group: current_benefit_package,
          hbx_enrollment_members: [hbx_enrollment_member],
          coverage_kind: 'dental',
          original_application_type: "phil wins"
        )
      end

      before do
        hbx_enrollment_two.update_attributes(:aasm_state => :inactive)
        assign(:hbx_enrollments, HbxEnrollment.enrollments_for_display_census_employee_show(census_employee))
        render template: 'employers/census_employees/show.html.erb'
      end

      it "doesn't show the waived coverage" do
        expect(rendered).to_not match(/Waiver Reason/)
      end
    end

    context "dependents" do
      let(:census_dependent1) do
        double(
          'CensusDependent1',
          persisted?: true,
          _destroy: true,
          valid?: true,
          relationship: 'child_under_26',
          first_name: 'jack',
          last_name: 'White',
          middle_name: 'bob',
          ssn: 123_123_123,
          dob: Time.zone.today,
          gender: 'male',
          employee_relationship: 'child_under_26',
          id: 1_231_623
        )
      end
      let(:census_dependent2) {double('CensusDependent2', persisted?: true, _destroy: true, valid?: true, relationship: 'child_26_and_over', first_name: 'jack', last_name: 'White', middle_name: 'bob', ssn: 123_123_123, dob: Time.zone.today) }
      before :each do
        allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(hbx_enrollment)
      end

      it "should get dependents title" do
        render template: "employers/census_employees/show.html.erb"
        expect(rendered).to match(/Dependents/)
      end

      it "should get child relationship when child_under_26" do
        allow(view).to receive(:link_to_add_fields).and_return(true)
        allow(census_employee).to receive(:census_dependents).and_return([census_dependent1])
        render template: "employers/census_employees/show.html.erb"
        expect(rendered).to match(/child/)
      end

      it "should get the Owner info" do
        render template: "employers/census_employees/show.html.erb"
        expect(rendered).to match(/Owner?/i)
      end
    end

    context "with health, dental, and past enrollments" do
      let(:decorated_dental_hbx_enrollment) { double(member_enrollments: [member_enrollment], product_cost_total: '',sponsor_contribution_total: '') }
      let(:dental_plan) { FactoryBot.create :benefit_markets_products_dental_products_dental_product, :with_issuer_profile }
      let(:dental_hbx_enrollment) do
        FactoryBot.create(
          :hbx_enrollment, :with_product,
          household: household,
          benefit_group: current_benefit_package,
          family: family,
          coverage_kind: 'dental',
          sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id
        )
      end
      let(:carrier_profile) { FactoryBot.build_stubbed(:carrier_profile) }
      let(:past_enrollments) do
        FactoryBot.create(
          :hbx_enrollment, :with_product,
          household: household,
          family: family,
          benefit_group: current_benefit_package,
          coverage_kind: 'dental',
          aasm_state: 'coverage_terminated'
        )
      end

      before :each do
        allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_package)
        allow(dental_hbx_enrollment).to receive(:product).and_return(dental_plan)
        allow(past_enrollments).to receive(:product).and_return(dental_plan)
        assign(:past_enrollments, [past_enrollments])
        allow(census_employee).to receive(:past_enrollments).and_return [past_enrollments]
        allow(past_enrollments).to receive(:total_employee_cost).and_return 0
        allow(dental_hbx_enrollment).to receive(:decorated_hbx_enrollment).and_return(decorated_hbx_enrollment)
      end

      it "should display past enrollments" do
        allow(past_enrollments).to receive(:coverage_year).and_return(TimeKeeper.date_of_record.last_year.year)
        allow(past_enrollments).to receive(:employer_profile).and_return(abc_profile)
        allow(past_enrollments).to receive(:decorated_hbx_enrollment).and_return(decorated_hbx_enrollment)
        allow(dental_hbx_enrollment).to receive(:total_employee_cost).and_return 0
        assign(:hbx_enrollments, [hbx_enrollment, dental_hbx_enrollment])
        render template: "employers/census_employees/show.html.erb"
        expect(rendered).to match(/#{hbx_enrollment.coverage_year} Health Coverage/i)
        expect(rendered).to match(/#{hbx_enrollment.coverage_year} dental Coverage/i)
        expect(rendered).to match(/Past Enrollments/i)
      end

      context "with not health, but dental and past enrollments" do
        before :each do
          allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_package)
          allow(census_employee).to receive_message_chain("active_benefit_group_assignment.active_and_waived_enrollments").and_return([dental_hbx_enrollment])
        end
        it "should display past enrollments" do
          assign(:hbx_enrollments, [dental_hbx_enrollment])
          allow(dental_hbx_enrollment).to receive(:total_employee_cost).and_return 1.0
          render template: "employers/census_employees/show.html.erb"
          expect(rendered).not_to match(/#{hbx_enrollment.coverage_year} health Coverage/i)
          expect(rendered).to match(/#{hbx_enrollment.coverage_year} dental Coverage/i)
          expect(rendered).to match(/Past Enrollments/i)
        end
      end

      context "only health, but no past enrollments" do
        before :each do
          assign(:past_enrollments, [])
          allow(census_employee).to receive(:enrollments_for_display).and_return([hbx_enrollment])
          allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_package)
          allow(hbx_enrollment).to receive(:total_employee_cost).and_return 0
          allow(census_employee).to receive_message_chain("active_benefit_group_assignment.hbx_enrollments").and_return([hbx_enrollment, dental_hbx_enrollment])
        end
        it "should not display past enrollments" do
          render template: "employers/census_employees/show.html.erb"
          expect(rendered).to match(/#{hbx_enrollment.coverage_year} health Coverage/i)
        end
      end

      context "only dental, but no past enrollments" do
        let(:group_enrollment) {BenefitSponsors::Enrollments::GroupEnrollment.new(product: dental_plan, member_enrollments: [member_enrollment], product_cost_total: '')}
        before :each do
          assign(:hbx_enrollments, [dental_hbx_enrollment])
          allow(dental_hbx_enrollment).to receive(:total_employee_cost).and_return 0
          allow(census_employee).to receive_message_chain("active_benefit_group_assignment.hbx_enrollments").and_return([dental_hbx_enrollment])
        end
        it "should not display past enrollments" do
          render template: "employers/census_employees/show.html.erb"
          expect(rendered).to match(/#{hbx_enrollment.coverage_year} dental Coverage/i)
        end
      end

      context "Employee status" do
        before :each do
          allow(census_employee).to receive(:enrollments_for_display).and_return([hbx_enrollment])
          allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_package)
          allow(past_enrollments).to receive(:total_employee_cost).and_return 0
          census_employee.terminate_employment(TimeKeeper.date_of_record - 10.days) && census_employee.save
          census_employee.coverage_terminated_on = nil
          census_employee.rehire_employee_role
          census_employee.aasm_state = :rehired
          census_employee.save
        end

        it "should display the rehired date and not the hired date" do
          render template: "employers/census_employees/show.html.erb"
          expect(rendered).to match(/Rehired/i)
        end

        it "if rehired then it shouldnot display the termination date" do
          render template: "employers/census_employees/show.html.erb"
          expect(rendered).not_to match(/Terminated:/i)
        end
      end

      context "Hiding Address in CensusEmployee page if linked and populated" do
        before :each do
          census_employee.aasm_state = 'employee_role_linked'
          census_employee.save!
          census_employee.reload
          allow(past_enrollments).to receive(:total_employee_cost).and_return 0
        end
        it "should not show address fields" do
          allow(census_employee).to receive(:enrollments_for_display).and_return([hbx_enrollment])
          allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_package)
          allow(census_employee).to receive(:address).and_return(address)

          render template: "employers/census_employees/show.html.erb"
          expect(rendered).not_to match(/#{address.address_1}/)
          expect(rendered).not_to match(/#{address.address_2}/)
          expect(rendered).not_to match(/#{address.city}/)
          expect(rendered).not_to match(/#{address.state}/i)
          expect(rendered).not_to match(/#{address.zip}/)
        end
      end
    end
  end

  context 'when employer has canceled benefit application' do

    before :each do
      view.extend BenefitSponsors::Engine.helpers
      sign_in user
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true, list_enrollments?: true))
      assign(:employer_profile, abc_profile)
      assign(:benefit_sponsorship, benefit_sponsorship)
      assign(:datatable, Effective::Datatables::EmployeeDatatable.new({id: abc_profile.id}))
      allow(SicCodeRatingFactorSet).to receive(:where).and_return([double(lookup: 1.0)])
      allow(EmployerGroupSizeRatingFactorSet).to receive(:where).and_return([double(lookup: 1.0)])
      benefit_application = census_employee.employer_profile.benefit_applications.first
      benefit_application.cancel!
      bga = census_employee.benefit_group_assignments.first
      bga.update_attributes(is_active: false)
      bga.reload
      census_employee.reload
      assign(:census_employee, census_employee)
      render template: "employers/census_employees/show.html.erb"
    end

    it 'should render template' do
      expect(rendered).to match(/Details/i)
    end
  end
end