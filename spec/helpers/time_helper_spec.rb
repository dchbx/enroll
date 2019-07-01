require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe TimeHelper, :type => :helper, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:employer_profile) { abc_profile }
  let(:plan_year) { initial_application }
  let(:person) { FactoryBot.create(:person) }
  let(:employee_role) {FactoryBot.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:enrollment) {FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household)}
  let(:individual_family) { FactoryBot.create(:family, :with_primary_family_member)}
  let(:individual_enrollment) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: individual_family,  household: individual_family.active_household)}

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

  describe "set_default_termination_date_value" do
    before do
      allow(family).to receive_message_chain("primary_applicant.person").and_return(person)
      allow(person).to receive(:has_consumer_role?).and_return true
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(employer_profile).to receive(:plan_years).and_return(plan_year)
    end
    it "sets to todays date if current_date is within the enrollments plan_year" do
      enrollment.effective_on = (TimeKeeper.date_of_record - 1.month)
      expect(helper.set_default_termination_date_value(enrollment)).to eq(TimeKeeper.date_of_record)
    end

    it "sets to last day of enrollment if current_date is outside the plan_year" do
      enrollment.effective_on = (TimeKeeper.date_of_record - 2.year)
      expect(helper.set_default_termination_date_value(enrollment)).to eq(enrollment.effective_on + 1.year - 1.day)
    end
  end

  describe "SET optional_effective_on date on a SEP" do
    let(:person_with_consumer_role) { FactoryBot.create(:person, :with_consumer_role) }
    let(:person_with_employee_role) { FactoryBot.create(:person, :with_employee_role) }

    context "for shop market" do
      before do
        allow(person).to receive(:active_employee_roles).and_return([employee_role])
        allow(employer_profile).to receive(:plan_years).and_return(plan_year)
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

      it "should return nil as minmum range" do
        expect(helper.sep_optional_date(family, 'min')).to eq nil
      end

      it "should return nil as maximum range" do
        end_of_year = TimeKeeper.date_of_record.end_of_year
        expect(helper.sep_optional_date(family, 'max')).to eq nil
      end
    end

    context "for person with dual roles" do
      before do
        allow(family).to receive_message_chain("primary_applicant.person").and_return(person)
        allow(person).to receive(:has_consumer_role?).and_return true
        allow(person).to receive(:active_employee_roles).and_return([employee_role])
        allow(employer_profile).to receive(:plan_years).and_return(plan_year)
        allow(plan_year).to receive(:start_on).and_return(TimeKeeper.date_of_record - 1.month)
        allow(plan_year).to receive(:end_on).and_return(TimeKeeper.date_of_record - 1.month + 1.year - 1.day)
      end

      it "returns minmum range as nil when market kind is ivl" do
        expect(helper.sep_optional_date(family, 'min', 'ivl')).to eq nil
      end

      it "returns maximum range as nil when market kind is ivl" do
        expect(helper.sep_optional_date(family, 'max', 'ivl')).to eq nil
      end

      it "returns minmum range as start_date of plan_year when market kind is shop" do
        expect(helper.sep_optional_date(family, 'min', 'shop')).to eq(plan_year.start_on)
      end

      it "returns maximum range as end_date of plan_year when market kind is shop" do
        expect(helper.sep_optional_date(family, 'max', 'shop')).to eq(plan_year.end_on)
      end

      it "returns minimum range as nil when market kind is nil" do
        expect(helper.sep_optional_date(family, 'min', nil)).to eq nil
      end

      it "returns maximum range as nil when market kind is nil" do
        expect(helper.sep_optional_date(family, 'max', nil)).to eq nil
      end
    end

    context "for person with no consumer or active employee roles" do
      before do
        allow(family).to receive_message_chain("primary_applicant.person").and_return(person)
        allow(person).to receive(:has_consumer_role?).and_return false
        allow(person).to receive(:active_employee_roles).and_return []
      end

      it "returns minmum range as nil" do
        expect(helper.sep_optional_date(family, 'min')).to eq nil
      end

      it "returns maximum range as nil" do
        expect(helper.sep_optional_date(family, 'max')).to eq nil
      end
    end
  end
end

