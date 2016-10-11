  require "rails_helper"

RSpec.describe Insured::FamiliesHelper, :type => :helper do

  describe "#plan_shopping_dependent_text" do
    let(:person) { FactoryGirl.build_stubbed(:person)}
    let(:family) { FactoryGirl.build_stubbed(:family, :with_primary_family_member, person: person) }
    let(:household) { FactoryGirl.build_stubbed(:household, family: family) }
    let(:hbx_enrollment) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household, hbx_enrollment_members: [hbx_enrollment_member, hbx_enrollment_member_two]) }
    let(:hbx_enrollment_member) { FactoryGirl.build_stubbed(:hbx_enrollment_member) }
    let(:hbx_enrollment_member_two) { FactoryGirl.build_stubbed(:hbx_enrollment_member, is_subscriber: false) }


    it "it should return subscribers full name in span with dependent-text class" do
      allow(hbx_enrollment_member_two).to receive(:is_subscriber).and_return(true)
      allow(hbx_enrollment_member).to receive_message_chain("person.full_name").and_return("Bobby Boucher")
      expect(helper.plan_shopping_dependent_text(hbx_enrollment)).to eq "<span class='dependent-text'>Bobby Boucher</span>"
    end

    it "it should return subscribers and dependents modal" do
      allow(hbx_enrollment_member).to receive_message_chain("person.full_name").and_return("Bobby Boucher")
      allow(hbx_enrollment_member).to receive_message_chain("person.find_relationship_with").and_return("Spouse")
      allow(hbx_enrollment_member_two).to receive_message_chain("person.full_name").and_return("Danny Boucher")
      expect(helper.plan_shopping_dependent_text(hbx_enrollment)).to match '<h4 class="modal-title">Coverage For</h4>'
    end

  end

  describe "#generate_options_for_effective_on_kinds" do
    it "it should return blank array" do
      options = helper.generate_options_for_effective_on_kinds([], TimeKeeper.date_of_record)
      expect(options).to eq []
    end

    it "it should return options" do
      options = helper.generate_options_for_effective_on_kinds(['date_of_event', 'fixed_first_of_next_month'], TimeKeeper.date_of_record)
      date = TimeKeeper.date_of_record
      expect(options).to eq [[date.to_s, 'date_of_event'], [(date.end_of_month+1.day).to_s, 'fixed_first_of_next_month']]
    end
  end

  describe "#render_plan_type_details" do
    let(:dental_plan_2015){FactoryGirl.create(:plan_template,:shop_dental, active_year: 2015, metal_level: "dental")}
    let(:dental_plan_2016){FactoryGirl.create(:plan_template,:shop_dental, active_year: 2016, metal_level: "dental", dental_level: "high")}
    let(:health_plan_2016){FactoryGirl.create(:plan_template,:shop_health, active_year: 2016, metal_level: "silver")}

    it "should return dental plan with dental_level = high for 2016 plan" do
      expect(helper.render_plan_type_details(dental_plan_2016)).to eq "<span class=\"dental-icon\">High</span>"
    end

    it "should return dental plan with metal_level = dental for 2015 plan" do
      expect(helper.render_plan_type_details(dental_plan_2015)).to eq "<span class=\"dental-icon\">Dental</span>"
    end

    it "should return health plan with metal_level = bronze" do
      expect(helper.render_plan_type_details(health_plan_2016)).to eq "<span class=\"silver-icon\">Silver</span>"
    end
  end

  describe "#show_employer_panel" do
    let(:person) {FactoryGirl.build(:person)}
    let(:employee_role) {FactoryGirl.build(:employee_role)}
    let(:census_employee) {FactoryGirl.build(:census_employee)}
    let(:person_with_employee_role) {FactoryGirl.create(:person, :with_employee_role)}

    it "should return false without employee_role" do
      expect(helper.newhire_enrollment_eligible?(nil)).to eq false
    end

    it "should return false with employee_role who has no census_employee" do
      allow(employee_role).to receive(:census_employee).and_return nil
      expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
    end

    context "with employee_role who has census_employee" do
      before :each do
        allow(employee_role).to receive(:census_employee).and_return census_employee
      end

      it "should return false when census_employee is not newhire_enrollment_eligible" do
        allow(census_employee).to receive(:newhire_enrollment_eligible?).and_return false
        expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
      end

      context "when census_employee is newhire_enrollment_eligible" do
        before do
          allow(census_employee).to receive(:newhire_enrollment_eligible?).and_return true
        end

        it "should return false when person can not select coverage" do
          allow(employee_role).to receive(:can_select_coverage?).and_return false
          expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
        end

        it "should return true when person can select coverage" do
          allow(employee_role).to receive(:can_select_coverage?).and_return true
          expect(helper.newhire_enrollment_eligible?(employee_role)).to eq true
        end
      end
    end
  end

  describe "has_writing_agent?" do
    let(:employee_role) { FactoryGirl.build(:employee_role) }

    it "should return false" do
      expect(helper.has_writing_agent?(employee_role)).to eq false
    end
  end

  describe "display_aasm_state?" do
    let(:person) { FactoryGirl.build_stubbed(:person)}
    let(:family) { FactoryGirl.build_stubbed(:family, :with_primary_family_member, person: person) }
    let(:household) { FactoryGirl.build_stubbed(:household, family: family) }
    let(:hbx_enrollment) { FactoryGirl.build_stubbed(:hbx_enrollment, household: household, hbx_enrollment_members: [hbx_enrollment_member]) }
    let(:hbx_enrollment_member) { FactoryGirl.build_stubbed(:hbx_enrollment_member) }
    states = ["coverage_selected", "coverage_canceled", "coverage_terminated", "shopping", "inactive", "unverified", "coverage_enrolled", "any_state"]
    show_for_ivl = ["coverage_selected", "coverage_canceled", "coverage_terminated"]

    context "IVL market" do
      before :each do
        allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      end
      states.each do |status|
        it "returns #{show_for_ivl.include?(status)} for #{status}" do
          hbx_enrollment.aasm_state = status
          expect(helper.display_aasm_state?(hbx_enrollment)).to eq show_for_ivl.include?(status)
        end
      end
    end

    context "SHOP market" do
      before :each do
        allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      end
      states.each do |status|
        it "returns true for #{status}" do
          hbx_enrollment.aasm_state = status
          expect(helper.display_aasm_state?(hbx_enrollment)).to eq true
        end
      end
    end
  end

  describe "ShopForPlan using SEP" do
    let(:person) {FactoryGirl.create(:person, :with_employee_role, :with_family)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:qle_first_of_month) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_first_of_month ) }
    let(:qle_with_date_options_available) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_first_of_month, date_options_available: true ) }
    let(:sep_without_date_options) { 
      sep = family.special_enrollment_periods.new
      sep.effective_on_kind = 'first_of_month'
      sep.qualifying_life_event_kind= qle_first_of_month
      sep.qualifying_life_event_kind_id = qle_first_of_month.id
      sep.qle_on= Date.new(TimeKeeper.date_of_record.year, 04, 14)
      sep.admin_flag = true
      sep
    }

    let(:sep_with_date_options) { 
      sep = family.special_enrollment_periods.new
      sep.effective_on_kind = 'first_of_month'
      sep.qualifying_life_event_kind= qle_first_of_month
      sep.qualifying_life_event_kind_id = qle_with_date_options_available.id
      sep.qle_on= Date.new(TimeKeeper.date_of_record.year, 04, 14)
      sep.admin_flag = true
      sep
    }
    context "when building ShopForPlan link" do

        it "should have class 'existing-sep-item' for a QLE type with date options available" do
          expect(helper.build_link_for_sep_type(sep_with_date_options)).to include "class=\"existing-sep-item\""
        end

        it "should be a link to 'insured/family_members' for a QLE type without date options available" do
          expect(helper.build_link_for_sep_type(sep_without_date_options)).to include "href=\"/insured/family_members"
        end
    end

    context "find QLE for SEP" do
      it "needs to return the right QLE for a given SEP" do
        expect(find_qle_for_sep(sep_with_date_options)).to eq qle_with_date_options_available
        expect(find_qle_for_sep(sep_without_date_options)).to eq qle_first_of_month
      end
    end

  end

end
