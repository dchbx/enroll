require "rails_helper"

RSpec.describe TimeHelper, :type => :helper do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
  let(:enrollment) {FactoryGirl.create(:hbx_enrollment, household: family.active_household)}

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
    it "sets the latest date able to terminate an enrollment to the last day of the year of the enrollment" do
      enrollment.effective_on = (TimeKeeper.date_of_record - 7.days)
      latest_date = Date.new(enrollment.effective_on.year, 12, 31)
      expect(helper.set_date_max_to_plan_end_of_year(enrollment)).to eq(latest_date)
    end
  end
end
