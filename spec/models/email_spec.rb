require 'rails_helper'

describe Email, :dbclean => :after_each do
  let(:person) {FactoryGirl.create(:person)}
  let(:valid_params) do
    {
      kind: "home",
      address: "test@test.com",
      person: person
    }
  end

  describe 'validations' do
    it { should validate_presence_of :address }
    it { should validate_presence_of :kind }

    describe 'email type' do

      context 'when empty' do
        let(:params){valid_params.deep_merge!({kind: ""})}
        it 'is invalid' do
          expect(Email.create(**params).errors[:kind].any?).to be_truthy
          expect(Email.create(**params).errors[:kind]).to eq ["Choose a type", " is not a valid email type"]
        end
      end

      context "when invalid" do
        let(:params){valid_params.deep_merge!(kind: "fake")}
        it 'is invalid' do
          expect(Email.create(**params).errors[:kind].any?).to be_truthy
          expect(Email.create(**params).errors[:kind]).to eq ["fake is not a valid email type"]
        end
      end

      valid_types = Email::KINDS
      valid_types.each do |type|
        context("when valid #{type} address") do
          let(:params){valid_params}
          it 'is valid' do
            params.deep_merge!({kind: type, address: "#{type}@#{type}.com"})
            record = Email.create(**params)
            expect(record).to be_truthy
            expect(record.errors.messages.size).to eq 0
          end
        end
      end
    end

    describe "address" do

      context "when empty" do
        let(:params){valid_params.deep_merge!({address: ""})}
        it "should give an error" do
          record = Email.create(**params)
          expect(record.errors[:address].any?).to be_truthy
          expect(record.errors[:address]).to eq ["is not valid", "can't be blank"]
        end
      end

      context "when invalid" do
        let(:params){valid_params.deep_merge!({address: "something invalid"})}
        it "should give an error" do
          record = Email.create(**params)
          expect(record.errors[:address].any?).to be_truthy
          expect(record.errors[:address]).to eq ["is not valid"]
        end
      end

      context "when adding already email present" do
        let(:params) {valid_params}
        it "should not throw an error" do
          expect(Email.create(**params).valid?).to be_truthy
        end
      end
    end

    describe 'presence' do
      [:address].each do |missing|
        it('is invalid without ' + missing.to_s) do
          trait = 'without_email_' + missing.to_s
          email = FactoryGirl.build(:email, trait.to_sym)
          expect(email).to be_invalid
        end
      end
    end
  end

  describe '#match' do
    let(:params){valid_params}
    let(:email) { Email.create(**params)}

    context 'emails are the same' do
      let(:other_email) { email.clone }
      it 'returns true' do
        expect(email.match(other_email)).to be_truthy
      end
    end

    context 'emails differ' do
      context 'by type' do
        let(:other_email) do
          e = email.clone
          e.kind = 'work'
          e
        end
        it 'returns false' do
          expect(email.match(other_email)).to be false
        end
      end

      context 'by address' do
        let(:other_email) do
          e = email.clone
          e.address = 'something@different.com'
          e
        end
        it 'returns false' do
          expect(email.match(other_email)).to be false
        end
      end
    end
  end
end
