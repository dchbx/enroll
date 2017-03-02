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

  describe "is_initial_employer?" do

    let(:active_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "active") }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolling") }
    let(:employer_profile1){ FactoryGirl.create(:employer_profile, plan_years: [active_plan_year]) }
    let(:employer_profile2){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year]) }

    it "should return true if employer is initial" do
      expect(subject.is_initial_employer?(employer_profile1)).to eq true
    end

    it "should return false if employer is not initial" do
      expect(subject.is_initial_employer?(employer_profile2)).to eq false
    end
  end

  describe "is_renewal_conversion_employer?" do

    let(:active_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "active") }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolling") }
    let(:employer_profile1){ FactoryGirl.create(:employer_profile, plan_years: [active_plan_year]) }
    let(:employer_profile2){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year,active_plan_year]) }

    it "should return true if employer is not renewal" do
      expect(subject.is_renewal_or_conversion_employer?(employer_profile1)).to eq false
    end

    it "should return true if employer is renewal" do
      expect(subject.is_renewal_or_conversion_employer?(employer_profile2)).to eq true
    end
  end

  describe "employer_plan_years" do

    let(:active_plan_year){ FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.at_beginning_of_month, aasm_state: "active") }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year,start_on: TimeKeeper.date_of_record.at_beginning_of_month.next_month,aasm_state: "renewing_enrolling") }
    let(:employer_profile2){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year,active_plan_year]) }

    let(:active_plan_year){ FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.at_beginning_of_month, aasm_state: "active") }
    let(:employer_profile1){ FactoryGirl.create(:employer_profile, plan_years: [active_plan_year]) }

    context "initial employer" do

      it "should return active plan year" do
        expect(subject.employer_plan_years(employer_profile1)).to eq [active_plan_year]
      end

    end

    context "renewal employer" do

      context "day is after 15th of this month" do

        before do
          allow(TimeKeeper).to receive(:date_of_record).and_return(TimeKeeper.date_of_record.at_beginning_of_month+ 20.days)
        end

        it "should returna active and renewal plan year" do
          expect(subject.employer_plan_years(employer_profile2)).to eq [renewing_plan_year,active_plan_year]
        end
      end

      context "day is on or before 15th of this month" do

        before do
          allow(TimeKeeper).to receive(:date_of_record).and_return(TimeKeeper.date_of_record.at_beginning_of_month)
        end

        it "should return active plan year" do
          expect(subject.employer_plan_years(employer_profile2)).to eq [active_plan_year]
        end
      end
    end
  end
end
