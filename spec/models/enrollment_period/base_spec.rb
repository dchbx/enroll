require 'rails_helper'

RSpec.describe EnrollmentPeriod::Base, :type => :model do
  let(:title)     { "Spec special enrollment period" }
  let(:start_on)  { TimeKeeper.date_of_record }
  let(:end_on)    { TimeKeeper.date_of_record + 30.days }

  let(:valid_params){
    {
      title: title,
      start_on: start_on,
      end_on: end_on,
    }
  }

  context "when initialized" do
    context "with no start_on" do
      let(:params) {valid_params.except(:start_on)}

      it "should be invalid" do
        expect(EnrollmentPeriod::Base.create(**params).errors[:start_on].any?).to be_truthy
      end
    end

    context "with no end_on" do
      let(:params) {valid_params.except(:end_on)}

      it "should be invalid" do
        expect(EnrollmentPeriod::Base.create(**params).errors[:end_on].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:base_enrollment_period) { EnrollmentPeriod::Base.new(**params) }

      it "should be valid" do
        expect(base_enrollment_period.valid?).to be_truthy
      end

      context "and correctly determines if a passed date falls between start_on and end_on" do
        let(:new_base_enrollment_period) { EnrollmentPeriod::Base.new }
        let(:invalid_date) { end_on + 1.day }
        let(:valid_date)   { start_on + 1.day }

        it "should return false if no date values are set" do
          expect(new_base_enrollment_period.contains?(valid_date)).to be_falsey
        end

        it "should return false for date outside range" do
          expect(base_enrollment_period.contains?(invalid_date)).to be_falsey
        end

        it "should return true for date within range" do
          expect(base_enrollment_period.contains?(valid_date)).to be_truthy
        end

      end

    end
  end

end
