require "rails_helper"

RSpec.describe TimeHelper, :type => :helper do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }

  describe "time remaining in words" do
    it "counts 90 days from user creating date" do
      expect(helper.time_remaining_in_words(person.created_at)).to eq("95 days")
    end
  end

  describe "set earliest date for terminating enrollment" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:enrollment) {FactoryGirl.create(:hbx_enrollment, household: family.active_household)}
    it "counts -7 days from enrollment effective date" do
      enrollment.effective_on = (TimeKeeper.date_of_record - 7.days)
      expect(helper.set_date_min_to_effective_on(enrollment, TimeKeeper.date_of_record)).to eq("-6D")
    end
  end
end
