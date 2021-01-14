require 'rails_helper'

RSpec.describe HbxAdminController, :type => :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:person_with_family) { FactoryBot.create(:person, :with_family) }
  let(:family) { person_with_family.primary_family }
  let(:person_with_fam_hbx_enrollment) { person_with_family.primary_family.active_household.hbx_enrollments.build }
  let(:tax_household) { family.active_household.tax_households.build }
  let(:eligibility_determination) { family.active_household.tax_households.first.eligibility_determinations.build(source: 'Admin') }
  let(:organization) do
    FactoryBot.create(:organization, hbx_profile: FactoryBot.create(:hbx_profile))
  end
  let(:valid_benefit_sponsorship)  { FactoryBot.create(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
  let(:valid_date)  { TimeKeeper.date_of_record.beginning_of_month }

  before :each do
    allow(user).to receive(:has_hbx_staff_role?).and_return(true)
    sign_in(user)
    EnrollRegistry[:apply_aggregate_to_enrollment].feature.stub(:is_enabled).and_return(false)
  end

  describe "POST edit_aptc_csr" do
    before do
      allow(HbxProfile).to receive(:current_hbx).and_return(organization)
      allow(Admin::Aptc).to receive(:calculate_slcsp_value).with(valid_date.year, family).and_return('100')
      allow(Admin::Aptc).to receive(:years_with_tax_household).with(family).and_return(valid_date.year)
    end

    it "should initialize the variables for the method and render the proper template" do
      post(:edit_aptc_csr, params: { person_id: person_with_family.id, family_id: family.id, year: valid_date.year}, format: :js)
      expect(subject).to render_template("hbx_admin/edit_aptc_csr_no_enrollment")
    end
  end

  describe "POST update_aptc_csr" do
    before do
      person_with_fam_hbx_enrollment.kind = 'individual'
      person_with_fam_hbx_enrollment.family = person_with_family.primary_family
      person_with_fam_hbx_enrollment.aasm_state = 'coverage_selected'
      person_with_fam_hbx_enrollment.effective_on = Date.new(valid_date.year, 10, valid_date.day)
      person_with_fam_hbx_enrollment.coverage_kind = 'health'
      person_with_fam_hbx_enrollment.save!
      tax_household.effective_starting_on = Date.new(valid_date.year, 10, valid_date.day)
      tax_household.save!
      eligibility_determination.max_aptc = 100
      eligibility_determination.csr_percent_as_integer = 50
      eligibility_determination.determined_at = Date.new(valid_date.year, 10, valid_date.day)
      eligibility_determination.determined_on = Date.new(valid_date.year, 10, valid_date.day)
      eligibility_determination.save!
      allow(Admin::Aptc).to receive(:find_enrollment_effective_on_date).and_return(valid_date)
      post(
        :update_aptc_csr,
        params: { 
          person: { person_id: person_with_family.id, family_id: family.id, current_year: valid_date.year },
          max_aptc: '1000',
          csr_percentage: 50
        },
        format: :js
      )
      family.reload
    end

    it 'should render the proper template' do
      expect(subject).to render_template("hbx_admin/update_aptc_csr")
    end

    it 'should create a new tax household object when there is a determination change' do
      expect(family.active_household.tax_households.count).to eq(2)
    end

    it 'should end date the old tax_households' do
      expect(family.active_household.tax_households.active_tax_household.count).to eq(1)
    end
  end

  describe "GET calculate_aptc_csr" do
    before do
      allow(HbxProfile).to receive(:current_hbx).and_return(organization)
      allow(Admin::Aptc).to receive(:calculate_slcsp_value).with(valid_date.year, family).and_return('100')
      allow(Admin::Aptc).to receive(:years_with_tax_household).with(family).and_return(valid_date.year)
    end

    it "should initialize the variables for the method and render the proper template" do
      get(:calculate_aptc_csr, params: { person_id: person_with_family.id, family_id: family.id, year: valid_date.year, max_aptc: 100 }, format: :js)
    end
  end
end
