require "rails_helper"

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe HbxAdminHelper, :type => :helper do
  let(:family)    { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:household) { FactoryGirl.create(:household, family: family)}
  let(:hbx)   { FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month - 40.days), applied_aptc_amount: 100)}
  let(:hbx_inactive)   { FactoryGirl.create(:hbx_enrollment, household: household, is_active: false, aasm_state: 'coverage_terminated', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month - 40.days), applied_aptc_amount: 100)}
  let(:hbx_without_aptc)   { FactoryGirl.create(:hbx_enrollment, household: household, is_active: true, aasm_state: 'coverage_selected', changing: false, effective_on: (TimeKeeper.date_of_record.beginning_of_month - 40.days), applied_aptc_amount: 0)}

  context "APTC Enrollments:" do
    it "returns a full name of a person given person_id" do
      expect(helper.full_name_of_person(family.person)).to eq family.person.full_name
    end

    it "returns the ehb rounded to two decimal places" do
      expect(helper.ehb_percent_for_enrollment(hbx.id)).to eq 99.43
    end

    it "returns the applied_aptc percent for an enrollment" do
      expect(helper.find_applied_aptc_percent(hbx.applied_aptc_amount, 214.00)).to eq 47
    end

    context "returns the correct class for td styling for current and past " do
      let(:past_month) { TimeKeeper.date_of_record.month == 1 ? 1 : TimeKeeper.date_of_record.month - 1 }
      let(:current_month) {TimeKeeper.date_of_record.month}
      let(:current_year) {TimeKeeper.date_of_record.year}

      it "returns the past-aptc-csr-data class for past_month" do
        if TimeKeeper.date_of_record.month == 1
          expect(helper.aptc_csr_data_type(current_year, Date::ABBR_MONTHNAMES[past_month])).to eq "current-aptc-csr-data"
        else
          expect(helper.aptc_csr_data_type(current_year, Date::ABBR_MONTHNAMES[past_month])).to eq "past-aptc-csr-data"
        end
      end

      it "returns the current-aptc-csr-data class for current_month" do
        expect(helper.aptc_csr_data_type(current_year, Date::ABBR_MONTHNAMES[current_month])).to eq "current-aptc-csr-data"
      end
    end

    context "returns inactive enrollments" do
      it "returns all cancelled and terminated enrollments" do
        expect(helper.inactive_enrollments(family, TimeKeeper.date_of_record.year)).to be_an_instance_of Mongoid::Criteria
        expect(helper.inactive_enrollments(family, TimeKeeper.date_of_record.year).selector["aasm_state"]["$in"]).to include("coverage_canceled", "coverage_terminated")
      end
    end

  end

end
end
