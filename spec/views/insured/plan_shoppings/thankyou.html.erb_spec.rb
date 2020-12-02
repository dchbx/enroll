require "rails_helper"

RSpec.describe "insured/thankyou.html.erb", dbclean: :after_each do

  context "shop enrollment" do
    let(:employee_role){FactoryBot.create(:employee_role)}
    let(:plan) do
      instance_double(
        BenefitMarkets::Products::HealthProducts::HealthProduct,
        issuer_profile: carrier_profile,
        title: "Your Selected Plan",
        kind: "health",
        active_year: 2018,
        metal_level_kind: :gold,
        id: "some product id"
      )
    end
    let(:hbx_enrollment) do
      HbxEnrollment.new(
        employee_role: employee_role,
        effective_on: 1.month.ago.to_date,
        updated_at: DateTime.now,
        kind: "employer_sponsored"
      )
    end
    let(:carrier_profile) { instance_double(BenefitSponsors::Organizations::IssuerProfile, legal_name: "carefirst") }
    let(:group_enrollment) do
      instance_double(
        BenefitSponsors::Enrollments::GroupEnrollment,
        product_cost_total: 200.00,
        sponsor_contribution_total: 100.00,
        employee_cost_total: 100.00
      )
    end
    let(:member_group)  do
      instance_double(
        BenefitSponsors::Members::MemberGroup,
        group_enrollment: group_enrollment
      )
    end

    before :each do
      assign(:plan, plan)
      assign(:enrollment, hbx_enrollment)
      assign(:person, employee_role.person)
      assign(:member_group, member_group)
    #  allow(@enrollment).to receive(:employee_role).and_return(true)
    #  allow(@enrollment).to receive(:is_shop?).and_return(true)
      allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true, can_access_progress?: true))
    end

    it 'should display the correct plan selection text' do
      render :template => "insured/plan_shoppings/thankyou.html.erb"
      expect(rendered).to have_selector('h1', text: 'Confirm Your Plan Selection')
      expect(rendered).to have_selector('h4', text: /Please review your current plan selection. Select PREVIOUS if /)
    end

    it 'should render coverage_information partial' do
      render :template => "insured/plan_shoppings/thankyou.html.erb"
      expect(response).to render_template(:partial => "insured/plan_shoppings/_coverage_information")
    end

    it "should have market" do
      render :template => "insured/plan_shoppings/thankyou.html.erb"
      expect(rendered).to match('Market')
      expect(rendered).to match('Employer Sponsored')
    end

    it "should have cobra msg" do
      allow(hbx_enrollment).to receive(:is_cobra_status?).and_return(true)
      render :template => "insured/plan_shoppings/thankyou.html.erb"
      expect(rendered).to match("Your employer may charge an additional administration fee for your COBRA/Continuation coverage. If you have any questions, please direct them to the Employer")
    end
  end
=begin
  #These examples need to be refactored to account for the DC new model IVL market - out of scope for ticket #41774
  #product instead of plan
  
  if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
    context "ivl enrollment" do
      let(:employee_role){FactoryBot.create(:employee_role)}
      let(:plan){FactoryBot.create(:plan)}
      let(:benefit_group){ FactoryBot.build(:benefit_group) }
      let(:hbx_enrollment){ HbxEnrollment.new(benefit_group: benefit_group, employee_role: employee_role, effective_on: 1.month.ago.to_date, updated_at: DateTime.now  ) }
      let(:carrier_profile) { double(legal_name: "carefirst")}

      before :each do
        @person = employee_role.person
        @plan = plan
        @enrollment = hbx_enrollment
        @benefit_group = benefit_group
        @reference_plan = @benefit_group.reference_plan
        @plan = UnassistedPlanCostDecorator.new(@plan, @enrollment)
        allow(@plan).to receive(:carrier_profile).and_return(carrier_profile)
        allow(view).to receive(:policy_helper).and_return(double('FamilyPolicy', updateable?: true))
      end

      it 'should display the correct plan selection text' do
        allow(@enrollment).to receive(:employee_role).and_return(false)
        allow(@enrollment).to receive(:is_cobra_status?).and_return(false)
        render :template => "insured/plan_shoppings/thankyou.html.erb"
        expect(rendered).to have_selector('h1', text: 'Confirm Your Plan Selection')
        expect(rendered).to have_selector('h4', text: /Please review your current plan selection. Select PREVIOUS if /)
        expect(rendered).to have_content(/You must complete these steps to enroll/i)
      end

      it 'should render agreement partial' do
        allow(@enrollment).to receive(:employee_role).and_return(false)
        allow(@enrollment).to receive(:is_cobra_status?).and_return(false)
        render :template => "insured/plan_shoppings/thankyou.html.erb"
        expect(response).to render_template(:partial => "insured/plan_shoppings/_individual_agreement")
      end

      it 'should render waive_confirmation partial' do
        allow(@enrollment).to receive(:employee_role).and_return(double)
        allow(@enrollment).to receive(:is_cobra_status?).and_return(false)
        render :template => "insured/plan_shoppings/thankyou.html.erb"
        expect(response).to render_template(partial: "ui-components/v1/modals/waive_confirmation_during_shopping", locals: {enrollment: hbx_enrollment})
      end

      it "should not render waive_confirmation partial" do
        allow(@enrollment).to receive(:employee_role).and_return(false)
        allow(@enrollment).to receive(:is_cobra_status?).and_return(false)
        render :template => "insured/plan_shoppings/thankyou.html.erb"
        expect(rendered).not_to have_selector('div#waive_confirm')
        expect(response).not_to render_template(partial: "insured/plan_shoppings/waive_confirmation_during_shopping", locals: {enrollment: hbx_enrollment})
      end
    end
  end
=end
end
