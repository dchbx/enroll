require 'rails_helper'

RSpec.describe Quote, type: :model, dbclean: :after_each do
	let(:valid_quote_params) {attributes_for(:quote)}
	let(:subject) {create :quote, :with_household_and_members}
	context "Validations" do ()
    it { is_expected.to validate_uniqueness_of(:claim_code).case_insensitive }
  end

  context "Associations" do
	  it { is_expected.to embed_many(:quote_households) }
	  it { is_expected.to embed_many(:quote_benefit_groups) }
	  it { is_expected.to accept_nested_attributes_for(:quote_households) }
  end

  context 'when quote state is created' do
    it 'should be draft' do
      expect(subject.aasm_state).to eq "draft"
    end
    it 'should have nil claim code' do
      expect(subject.claim_code).to be_nil
    end
  end

  context "when valid quote is published" do
    before do
      subject.publish!
    end

    it "should publish"  do
      expect(subject.aasm_state).to eq "published"
    end

		it "claim code should not be blank" do
			expect(subject.claim_code).not_to be_nil
		end

		it "claim code should be 9 characters long" do
			expect(subject.employer_claim_code.length).to eq(9)
		end

    context " published quote is copied" do
      before do
        @copy = subject.clone
      end

      it 'should be draft' do
        expect(@copy.aasm_state).to eq "draft"
      end

      it 'should have nil claim code' do
        expect(@copy.claim_code).to be_nil
      end

      it 'should have quote name based on original plus (1)' do
        expect(@copy.quote_name).to eq subject.quote_name + '(1)'
      end

      it 'there should be two quotes' do
        expect(Quote.count).to eq 2
      end
    end

    context " copied quote is copied" do
      before do
        @copy = subject.clone
        @copied = @copy.clone
      end
      it 'should append  (1) to the quote_name for first copy' do
        expect(@copy.quote_name).to eq subject.quote_name + '(1)'
      end
      it 'should append (2) to the quote name for the second copy' do
        expect(@copied.quote_name).to eq subject.quote_name + '(2)'
      end
      it 'should append one to the highest quote name suffix' do
        @copy.update_attributes(quote_name: 'wags(10)')
        unrelated_quote = subject.clone
        @copy_again = @copy.clone
        expect(@copy_again.quote_name).to eq 'wags(11)'
      end
    end
  end
end
