require 'rails_helper'

RSpec.describe Quote, type: :model, dbclean: :after_each do
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

	context "when a claim code is generated" do
		it "should not be blank" do
			expect(subject.employer_claim_code).not_to be_nil
		end

		it "should be 9 characters long" do
			expect(subject.employer_claim_code.length).to eq(9)
		end

	end

end
