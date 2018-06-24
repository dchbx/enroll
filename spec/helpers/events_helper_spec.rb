require "rails_helper"

class EventsHelperSlug
  include EventsHelper
end

describe EventsHelper, "given an address_kind" do

  subject { EventsHelperSlug.new }

  describe "when the address kind is 'primary'" do
    it "should return address kind as 'work'" do
      expect(subject.office_location_address_kind("primary")).to eq "work"
    end
  end

  describe "when the address kind is 'branch'" do
    it "should return address kind as 'work'" do
      expect(subject.office_location_address_kind("branch")).to eq "work"
    end
  end

  describe "when the address kind is anything else" do
    it "should return address kind as the same" do
      expect(subject.office_location_address_kind("slkdjfkld")).to eq "slkdjfkld"
    end
  end

  describe "is_initial_or_conversion_employer?" do

    let(:active_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "active") }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolling") }
    let(:employer_profile1){ FactoryGirl.create(:employer_profile, plan_years: [active_plan_year]) }
    let(:employer_profile2){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year]) }

    it "should return true if employer is initial" do
      expect(subject.is_initial_or_conversion_employer?(employer_profile1)).to eq true
    end

    it "should return false if employer is not initial" do
      expect(subject.is_initial_or_conversion_employer?(employer_profile2)).to eq false
    end

    it "should return true if employer is conversion has one active plan year & registered_on date not b/w active plan year start and end date" do
      employer_profile1.profile_source='conversion'
      employer_profile1.registered_on=TimeKeeper.date_of_record-1.year
      employer_profile1.save
      expect(subject.is_initial_or_conversion_employer?(employer_profile1)).to eq true
    end
  end


  describe "is_renewal_employer?" do
    let(:active_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "active") }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolling") }
    let(:employer_profile){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year,active_plan_year]) }

    it "should return true if employer is renewal_employer" do
      expect(subject.is_renewal_employer?(employer_profile)).to eq true
    end

    it "should return false if employer is not renewal_employer" do
      employer_profile.profile_source='conversion'
      employer_profile.save
      expect(subject.is_renewal_employer?(employer_profile)).to eq false
    end
  end

  describe "is_new_conversion_employer?" do
    let(:active_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "active", is_conversion: true) }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolling") }
    let(:employer_profile){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year,active_plan_year]) }

    it "should return false if employer is not conversion_employer" do
      expect(subject.is_new_conversion_employer?(employer_profile)).to eq false
    end

    it "should return true if employer is new conversion_employer" do
      employer_profile.profile_source='conversion'
      employer_profile.save
      expect(subject.is_new_conversion_employer?(employer_profile)).to eq true
    end
  end

  describe "is_renewing_conversion_employer?" do
    let(:active_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "active") }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolling") }
    let(:employer_profile2){ FactoryGirl.create(:employer_profile,profile_source:'conversion', plan_years: [renewing_plan_year,active_plan_year]) }
    let(:employer_profile1){ FactoryGirl.create(:employer_profile,profile_source:'conversion', plan_years: [active_plan_year]) }

    it "should return false if conversion employer renewing has only active plan year" do
      expect(subject.is_renewing_conversion_employer?(employer_profile1)).to eq false
    end

    it "should return true if conversion employer renewing" do
      employer_profile2.registered_on=TimeKeeper.date_of_record-1.year
      employer_profile2.save
      expect(subject.is_renewing_conversion_employer?(employer_profile2)).to eq true
    end
  end

  describe "is_renewal_or_conversion_employer?" do

    let(:employer_profile){ FactoryGirl.create(:employer_profile) }

    it "should return true if employer is renewal employer" do
      allow(subject).to receive(:is_renewal_employer?).with(employer_profile).and_return true
      expect(subject.is_renewal_or_conversion_employer?(employer_profile)).to eq true
    end

    it "should return fasle if employer is not renewal employer" do
      allow(subject).to receive(:is_renewal_employer?).with(employer_profile).and_return false
      expect(subject.is_renewal_or_conversion_employer?(employer_profile)).to eq false
    end
    it "should return true if employer new_conversion_employer" do
      allow(subject).to receive(:is_new_conversion_employer?).with(employer_profile).and_return true
      expect(subject.is_renewal_or_conversion_employer?(employer_profile)).to eq true
    end

    it "should return false if employer is not new_conversion_employer" do
      allow(subject).to receive(:is_new_conversion_employer?).with(employer_profile).and_return false
      expect(subject.is_renewal_or_conversion_employer?(employer_profile)).to eq false
    end
    it "should return true if employer is renewing conversion employer" do
      allow(subject).to receive(:is_renewing_conversion_employer?).with(employer_profile).and_return true
      expect(subject.is_renewal_or_conversion_employer?(employer_profile)).to eq true
    end
  end

  describe "is_office_location_address_valid?" do

    let(:phone) { FactoryGirl.build(:phone) }
    let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }
    let(:address1)  { Address.new(kind: "branch", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }
    let(:office_location) { OfficeLocation.new(is_primary: true, address: address, phone: phone)}
    let(:office_location1) { OfficeLocation.new(is_primary: true, address: address1, phone: phone)}

    context "office location with valid address kind" do

      it "should return true" do
        expect(subject.is_office_location_address_valid?(office_location)).to eq true
      end
    end

    context "office location with invalid address kind" do

      it "should return false " do
        expect(subject.is_office_location_address_valid?(office_location1)).to eq false
      end
    end
  end

  describe "is_office_location_phone_valid?" do

    let(:phone) { FactoryGirl.build(:phone, kind:'home') }
    let(:phone1) { FactoryGirl.build(:phone, kind:'phone main main') }
    let(:address)  { Address.new(kind: "primary", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }
    let(:address1)  { Address.new(kind: "branch", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }
    let(:office_location) { OfficeLocation.new(is_primary: true, address: address, phone: phone)}
    let(:office_location1) { OfficeLocation.new(is_primary: true, address: address1, phone: phone1)}

    context "office location with valid phone kind" do

      it "should return true" do
        expect(subject.is_office_location_phone_valid?(office_location)).to eq true
      end
    end

    context "office location with invalid phone kind" do

      it "should return false " do
        expect(subject.is_office_location_phone_valid?(office_location1)).to eq false
      end
    end
  end

end

describe EventsHelper, "transforming a qualifying event kind for external xml" do

  RESULT_PAIR = {
    "relocate" => "location_change",
    "eligibility_change_immigration_status" => "citizen_status_change",
    "lost_hardship_exemption" => "eligibility_change_assistance",
    "eligibility_change_income" => "eligibility_change_assistance",
    "court_order" => "medical_coverage_order",
    "domestic_partnership" => "entering_domestic_partnership",
    "new_eligibility_member" => "drop_family_member_due_to_new_eligibility",
    "new_eligibility_family" => "drop_family_member_due_to_new_eligibility",
    "employer_sponsored_coverage_termination" => "eligibility_change_employer_ineligible",
    "divorce" => "divorce"
  }

  subject { EventsHelperSlug.new }

  RESULT_PAIR.each_pair do |k,v|
    it "maps \"#{k}\" to \"#{v}\"" do
      eligibility_event = instance_double(HbxEnrollment, :eligibility_event_kind => k)
      expect(subject.xml_eligibility_event_uri(eligibility_event)).to eq "urn:dc0:terms:v1:qualifying_life_event##{v}"
    end
  end

end

describe EventsHelper, "selecting plan years to be exported" do
  subject { EventsHelperSlug.new }

  describe "plan_years_for_manual_export" do
    let (:employer_profile) { FactoryGirl.create(:employer_with_planyear) }
    let (:ren_employer_profile) { FactoryGirl.create(:employer_with_renewing_planyear) }
    let (:plan_year) { employer_profile.plan_years.first }
    let (:act_plan_year) { ren_employer_profile.plan_years.first }
    let (:ren_plan_year) { ren_employer_profile.plan_years.last }


    context "draft plan year" do
      it "should return []" do
        expect(subject.plan_years_for_manual_export(employer_profile)).to eq []
      end
    end

    context "enrolled plan year" do
      before do
        plan_year.update_attributes({:aasm_state => "enrolled"})
      end

      it "should return the plan year" do
        expect(subject.plan_years_for_manual_export(employer_profile)).to eq [plan_year]
      end
    end

    context "terminated plan year with future date of termination" do
      before do
        plan_year.update_attributes({:terminated_on => TimeKeeper.date_of_record + 1.month,
                                     :aasm_state => "terminated"})
      end

      it "should return the plan year" do
        expect(subject.plan_years_for_manual_export(employer_profile)).to eq [plan_year]
      end
    end

    context "expired plan year" do
      before do
        plan_year.update_attributes({:aasm_state => "expired"})
      end

      it "should return the expired plan year" do
        expect(subject.plan_years_for_manual_export(employer_profile)).to eq [plan_year]
      end
    end

    context "active and canceled plan year" do
      before do
        ren_plan_year.update_attributes({:aasm_state => "renewing_canceled"})
      end

      it "should not return the plan year" do
        expect(subject.plan_years_for_manual_export(ren_employer_profile)).to eq [act_plan_year]
      end
    end
  end
end