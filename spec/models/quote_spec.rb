require 'rails_helper'

RSpec.describe Quote, type: :model do
	let(:valid_quote_params) {attributes_for(:quote)}
	let(:subject) {create :quote}

	context "Validations" do ()
    it { is_expected.to validate_uniqueness_of(:claim_code).case_insensitive }
  end

  context "Associations" do
	  it { is_expected.to embed_many(:quote_households) }
	  it { is_expected.to embed_many(:quote_benefit_groups) }
	  it { is_expected.to accept_nested_attributes_for(:quote_households) }
  end

  context "when valid quote is published" do 
    before do 
      subject.publish!
    end

    it "should publish"  do 
      expect(subject.aasm_state).to eq "published"
    end
  end

end
