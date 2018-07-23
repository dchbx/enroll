require "rails_helper"

describe RenewalPlanMapping, :type => :model do
  subject { RenewalPlanMapping.new(start_on: TimeKeeper.date_of_record, end_on: TimeKeeper.date_of_record + 6.months, renewal_plan_id: BSON::ObjectId.new ) }
  it "check for attributes" do
    expect(subject).to be_valid
  end

  it "is invalid renewal plan start on" do
    subject.start_on = nil
    expect(subject).to_not be_valid
  end

  it " is invalid renewal plan id " do
    subject.renewal_plan_id = nil
    expect(subject).to_not be_valid
  end

end