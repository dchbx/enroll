require "rails_helper"

describe CompositeTierContribution, "given nothing" do

  let(:validation_errors) do
    subject.valid?
    subject.errors
  end

  it "has errors on composite_rating_tier" do
    expect(validation_errors.has_key?(:composite_rating_tier)).to be_truthy
  end
end

describe CompositeTierContribution, "with validations" do
  CompositeRatingTier::NAMES.each do |val|
    it "accepts #{val} as a composite_rating_tier" do
      subject.composite_rating_tier = val
      expect(subject).to be_valid
    end
  end

  it "rejects a composite_rating_tier that is not one of the correct names" do
    subject.composite_rating_tier = "dslajfkldsjflkejf"
    subject.valid?
    expect(subject.errors.has_key?(:composite_rating_tier)).to be_truthy
  end

  it "rejects an employer_contribution percent > 100" do
    subject.employer_contribution_percent = 100.01
    subject.valid?
    expect(subject.errors.has_key?(:employer_contribution_percent)).to be_truthy
  end

  it "rejects an employer_contribution percent < 0" do
    subject.employer_contribution_percent = -0.01
    subject.valid?
    expect(subject.errors.has_key?(:employer_contribution_percent)).to be_truthy
  end

  it "accepts an employer_contribution percent == 100" do
    subject.employer_contribution_percent = 100.00
    subject.valid?
    expect(subject.errors.has_key?(:employer_contribution_percent)).to be_falsey
  end
end
