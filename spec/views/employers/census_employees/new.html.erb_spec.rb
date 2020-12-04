require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe "employers/census_employees/new.html.erb", dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: current_benefit_package) }

  before :each do
    @user = FactoryBot.create(:user)
    p=FactoryBot.create(:person, user: @user)
    @hbx_staff_role = FactoryBot.create(:hbx_staff_role, person: p, hbx_profile: site.owner_organization.hbx_profile)

    sign_in @user
    assign(:employer_profile, abc_profile)
    assign(:benefit_sponsorship, abc_profile.active_benefit_sponsorship)
    assign(:census_employee, census_employee)
    allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: true))
    render "employers/census_employees/new"
  end

  context 'for cobra' do
    it 'should have cobra area' do
      expect(rendered).to  have_selector('div#cobra_info')
    end

    it "should have cobra checkbox" do
      expect(rendered).to match /Check the box if this person is already in enrolled into COBRA\/Continuation outside of #{Settings.site.short_name}/
      expect(rendered).to have_selector('input#census_employee_existing_cobra')
    end

    it "should have cobra_begin_date_field" do
      expect(rendered).to have_selector('div#cobra_begin_date_field')
      expect(rendered).to match /COBRA Begin Date/
      expect(rendered).to have_selector('.interaction-field-control-census-employee-cobra_begin_date')
    end
  end
end
