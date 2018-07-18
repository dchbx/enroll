require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe "hbx_admin/_edit_aptc_csr", :dbclean => :after_each do
    let(:person) { FactoryGirl.create(:person, :with_family ) }
    let(:user) { FactoryGirl.create(:user, person: person) }
    let(:year) { TimeKeeper.date_of_record.year }
    
    before :each do
      sign_in(user)
      assign(:person, person)
      assign(:family, person.primary_family)
      assign(:months_array,  Date::ABBR_MONTHNAMES.compact)
      assign(:household_info, Admin::Aptc.build_household_level_aptc_csr_data(year, person.primary_family, [])) # Case with no Enrollment
      assign(:household_members, [{ person.id =>[102.0, 102.0] }] )
      assign(:year_options, [2016, 2017])
      assign(:current_year, 2016)
      family = person.primary_family
      active_household = family.households.first
      hbx_enrollments = active_household.hbx_enrollments
      tax_household = FactoryGirl.create(:tax_household, household: active_household )
      eligibility_determination = FactoryGirl.create(:eligibility_determination, tax_household: tax_household)
      allow(family).to receive(:active_household).and_return active_household
      allow(active_household).to receive(:latest_active_tax_household).and_return tax_household
      allow(tax_household).to receive(:latest_eligibility_determination).and_return eligibility_determination
      allow(active_household).to receive(:hbx_enrollments).and_return hbx_enrollments   
    end
    
    context "without enrollment" do
      it "Should display the Editing APTC/CSR text" do
        render "hbx_admin/edit_aptc_csr_no_enrollment.html.erb", person: person, family: person.primary_family   
        expect(rendered).to match(/Editing APTC \/ CSR for:/)
      end

      it "Should display Person Demographics Information" do
        render "hbx_admin/edit_aptc_csr_no_enrollment.html.erb", person: person, family: person.primary_family   
        expect(rendered).to match(/HBX ID/)
        expect(rendered).to match(/Name/)
        expect(rendered).to match(/DOB/)
        expect(rendered).to match(/SSN/)
      end

      it "Should display the Household Information" do
        render "hbx_admin/edit_aptc_csr_no_enrollment.html.erb", person: person, family: person.primary_family
        months_array = Date::ABBR_MONTHNAMES.compact
        months_array.each do |month|
          expect(rendered).to match(/month/)
        end
        expect(rendered).to match(/MAX APTC/i)
        expect(rendered).to match(/AVAILABLE APTC/i)
        expect(rendered).to match(/CSR % AS INTEGER/i)
        expect(rendered).to match(/SLCSP/i)
         expect(rendered).to match(/Household Member\(s\)/i)
        expect(rendered).to match(/APTC Amount \/ Percent Ratio/i)
      end
    end

    context "with enrollment" do
      let(:family)       { FactoryGirl.create(:family, :with_primary_family_member) }
      let(:household) {FactoryGirl.create(:household, family: family)}
      let!(:hbx_with_aptc_1) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month - 40.days), applied_aptc_amount: 100)}
      let!(:hbx_with_aptc_2) {FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days), applied_aptc_amount: 210)}
      let!(:hbx_enrollments) {[hbx_with_aptc_1, hbx_with_aptc_2]} 
      let!(:hbxs) { double("hbxs") }
      before :each do
        assign(:person, person)
        assign(:family, person.primary_family)
        family = person.primary_family
        active_household = family.households.first
        assign(:family, person.primary_family)
        assign(:months_array,  Date::ABBR_MONTHNAMES.compact)
        assign(:enrollments_info, Admin::Aptc.build_enrollments_data(person.primary_family, [], [], 112, 87, {})) # Case with no Enrollment
        assign(:household_members, [{ person.id =>[102.0, 102.0] }] )
        allow(hbxs).to receive(:canceled_and_terminated).and_return hbxs
        allow(hbxs).to receive(:with_plan).and_return hbxs
        allow(hbxs).to receive(:with_aptc).and_return hbxs
        allow(hbxs).to receive(:by_year).and_return hbxs
        allow(hbxs).to receive(:by_year).and_return hbxs
        allow(hbxs).to receive(:+).and_return hbxs
        allow(hbxs).to receive(:without_aptc).and_return hbxs
        allow(hbxs).to receive(:each).and_return hbx_with_aptc_1
        allow(active_household).to receive(:hbx_enrollments).and_return hbxs
      end

      it "Should display the Editing APTC/CSR text" do
        render "hbx_admin/edit_aptc_csr_active_enrollment.html.erb", person: person, family: person.primary_family   
        expect(rendered).to match(/Editing APTC \/ CSR for:/)
      end

      it "Should display Person Demographics Information" do
        render "hbx_admin/edit_aptc_csr_no_enrollment.html.erb", person: person, family: person.primary_family   
        expect(rendered).to match(/HBX ID/)
        expect(rendered).to match(/Name/)
        expect(rendered).to match(/DOB/)
        expect(rendered).to match(/SSN/)
      end

      it "Should display the Household Information" do
        render "hbx_admin/edit_aptc_csr_no_enrollment.html.erb", person: person, family: person.primary_family
        months_array = Date::ABBR_MONTHNAMES.compact
        months_array.each do |month|
          expect(rendered).to match(/month/)
        end
        expect(rendered).to match(/MAX APTC/i)
        expect(rendered).to match(/AVAILABLE APTC/i)
        expect(rendered).to match(/CSR % AS INTEGER/i)
        expect(rendered).to match(/SLCSP/i)
        expect(rendered).to match(/Household Member\(s\)/i)
        expect(rendered).to match(/APTC Amount \/ Percent Ratio/i)
      end
    end
end
end
