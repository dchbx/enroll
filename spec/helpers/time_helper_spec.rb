require "rails_helper"

RSpec.describe TimeHelper, :type => :helper do
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
  let(:enrollment) {FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
  let(:individual_family) { FactoryGirl.create(:family, :with_primary_family_member)}
  let(:individual_enrollment) {FactoryGirl.create(:hbx_enrollment, :individual_unassisted, household: individual_family.active_household)}

  before :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  describe "time remaining in words" do
    it "counts 95 days from the passed in date" do
      expect(helper.time_remaining_in_words(TimeKeeper.date_of_record)).to eq("95 days")
    end
  end

  describe "set earliest date for terminating enrollment" do
    it "counts -7 days from enrollment effective date" do
      enrollment.effective_on = (TimeKeeper.date_of_record - 7.days)
      expect(helper.set_date_min_to_effective_on(enrollment)).to eq(TimeKeeper.date_of_record - 6.days)
    end
  end

  describe "set latest date for terminating enrollment" do
    context "for enrollment in shop market"do
      it "sets the latest date able to terminate an enrollment to be 1 year less 1 day from the enrollment start date" do
        enrollment.effective_on = (TimeKeeper.date_of_record - 7.days)
        #latest_date = Date.new(enrollment.effective_on.year, 12, 31)
        latest_date = enrollment.effective_on + 1.year - 1.day
        expect(helper.set_date_max_to_plan_end_of_year(enrollment)).to eq(latest_date)
      end
    end

    context "for enrollment in individual market"do
      it "sets the latest date able to terminate an enrollment to be the last day of the calendar year in which the enrollment starts" do
        individual_enrollment.effective_on = (TimeKeeper.date_of_record - 7.days)
        latest_date = Date.new(individual_enrollment.effective_on.year, 12, 31)
        expect(helper.set_date_max_to_plan_end_of_year(individual_enrollment)).to eq(latest_date)
      end
    end
  end

  describe "SET optional_effective_on date on a SEP" do
    let(:person_with_consumer_role) { FactoryGirl.create(:person, :with_consumer_role) }
    let(:person_with_employee_role) { FactoryGirl.create(:person, :with_employee_role) }
    let(:person) { FactoryGirl.create(:person) }
    let(:employer_profile) {FactoryGirl.create(:employer_profile)}
    let(:employee_role1) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
    let(:plan_year) {double("PlanYear")}
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member,person: person)}

    context "for shop market" do
      before do
        allow(person).to receive(:active_employee_roles).and_return([employee_role1])
        allow(employer_profile).to receive(:plan_years).and_return(plan_year)
        allow(plan_year).to receive(:published_or_renewing_published).and_return(plan_year)
        allow(plan_year).to receive(:start_on).and_return(TimeKeeper.date_of_record - 1.month)
        allow(plan_year).to receive(:end_on).and_return(TimeKeeper.date_of_record - 1.month + 1.year - 1.day)
      end

      it "returns minmum range as start_date of plan_year" do
        expect(helper.sep_optional_date(family, 'min')).to eq(plan_year.start_on)
      end

      it "returns maximum range as end_date of plan_year" do
        expect(helper.sep_optional_date(family, 'max')).to eq(plan_year.end_on)
      end
    end

    context "for individual market" do
      before do
        allow(family).to receive_message_chain("primary_applicant.person").and_return(person_with_consumer_role)
        allow(person).to receive(:has_consumer_role?).and_return false
      end

      it "returns minmum range as beginning of the year" do
        beginning_of_year = TimeKeeper.date_of_record.beginning_of_year
        expect(helper.sep_optional_date(family, 'min')).to eq(beginning_of_year)
      end

      it "returns maximum range as end of the year" do
        end_of_year = TimeKeeper.date_of_record.end_of_year
        expect(helper.sep_optional_date(family, 'max')).to eq(end_of_year)
      end
    end

    context "for person with dual roles" do
      let(:beginning_of_year) {TimeKeeper.date_of_record.beginning_of_year}
      let(:end_of_year) {TimeKeeper.date_of_record.end_of_year}
      before do
        allow(family).to receive_message_chain("primary_applicant.person").and_return(person)
        allow(person).to receive(:has_consumer_role?).and_return true
        allow(person).to receive(:active_employee_roles).and_return([employee_role1])
        allow(employer_profile).to receive(:plan_years).and_return(plan_year)
        allow(plan_year).to receive(:published_or_renewing_published).and_return(plan_year)
        allow(plan_year).to receive(:start_on).and_return(TimeKeeper.date_of_record - 1.month)
        allow(plan_year).to receive(:end_on).and_return(TimeKeeper.date_of_record - 1.month + 1.year - 1.day)
      end

      it "returns minmum range as beginning of the year when market kind is ivl" do
        expect(helper.sep_optional_date(family, 'min', 'ivl')).to eq(beginning_of_year)
      end

      it "returns maximum range as end of the year when market kind is ivl" do
        expect(helper.sep_optional_date(family, 'max', 'ivl')).to eq(end_of_year)
      end

      it "returns minmum range as start_date of plan_year when market kind is shop" do
        expect(helper.sep_optional_date(family, 'min', 'shop')).to eq(plan_year.start_on)
      end

      it "returns maximum range as end_date of plan_year when market kind is shop" do
        expect(helper.sep_optional_date(family, 'max', 'shop')).to eq(plan_year.end_on)
      end

      it "returns minimum range as MIN of(start_date of plan_year, beginning_of_year) when market kind is nil" do
        expect(helper.sep_optional_date(family, 'min', nil)).to eq([plan_year.start_on, beginning_of_year].min)
      end

      it "returns maximum range as MAX of(end_date of plan_year, end_of_year) when market kind is nil" do
        expect(helper.sep_optional_date(family, 'max', nil)).to eq([plan_year.end_on, end_of_year].max)
      end

    end

    context "for person with no consumer or active employee roles" do
      before do
        allow(family).to receive_message_chain("primary_applicant.person").and_return(person)
        allow(person).to receive(:has_consumer_role?).and_return false
        allow(person).to receive(:active_employee_roles).and_return []
      end

      it "returns minmum range as beginning of the year" do
        beginning_of_year = TimeKeeper.date_of_record.beginning_of_year
        expect(helper.sep_optional_date(family, 'min')).to eq(beginning_of_year)
      end

      it "returns maximum range as end of the year" do
        end_of_year = TimeKeeper.date_of_record.end_of_year
        expect(helper.sep_optional_date(family, 'max')).to eq(end_of_year)
      end
    end
  end
end
