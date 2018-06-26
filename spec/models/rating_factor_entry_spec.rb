require "rails_helper"

describe RatingFactorEntry do
  let(:validation_errors) {
    subject.valid?
    subject.errors
  }

  it "requires a factor key" do
    expect(validation_errors.has_key?(:factor_key)).to be_truthy
  end

  it "requires a factor value" do
    expect(validation_errors.has_key?(:factor_value)).to be_truthy
  end
end
