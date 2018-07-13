require 'rails_helper'

module BenefitMarkets
	RSpec.describe Products::ActuarialFactors::GroupSizeActuarialFactor do
		let(:validation_errors) {
			subject.valid?
			subject.errors
		}

		it "requires an issuer profile" do
			expect(validation_errors.has_key?(:issuer_profile_id)).to be_truthy  
		end

		it "requires a default factor value" do
			expect(validation_errors.has_key?(:default_factor_value)).to be_truthy  
		end

		it "requires an active year" do
			expect(validation_errors.has_key?(:active_year)).to be_truthy  
		end

		it "requires a max_integer_factor_key" do
			expect(validation_errors.has_key?(:max_integer_factor_key)).to be_truthy  
		end
	end

	RSpec.describe Products::ActuarialFactors::GroupSizeActuarialFactor, "given
- a carrier profile
- an active year
- a default factor value
- no rating factor entries
- a max_integer_factor_key
	" do

		let(:default_factor_value) { 1.234567 }
		let(:issuer_profile_id) { BSON::ObjectId.new }
		let(:active_year) { 2015 }

		subject do
			Products::ActuarialFactors::GroupSizeActuarialFactor.new({
				:default_factor_value => default_factor_value,
				:active_year => active_year,
				:issuer_profile_id => issuer_profile_id,
				:max_integer_factor_key => 3
			})
		end

		it "is valid" do
			expect(subject.valid?).to be_truthy
		end

		it "returns the default factor on all lookups" do
			expect(subject.lookup(2)).to eq default_factor_value
		end

	end

	RSpec.describe Products::ActuarialFactors::GroupSizeActuarialFactor, "given
- a rating factor entry with key '23' and value '1.345'
- a max_integer_factor_key of '30'
	" do

		subject do
			Products::ActuarialFactors::GroupSizeActuarialFactor.new({
				:actuarial_factor_entries => [
					Products::ActuarialFactors::ActuarialFactorEntry.new({
						:factor_key => '23',
						:factor_value => 1.345
					})
				],
				:max_integer_factor_key => 30
			})
		end

		it "returns the '1.345' for a lookup of 23" do
			expect(subject.lookup(23)).to eq 1.345
		end

	end

	RSpec.describe Products::ActuarialFactors::GroupSizeActuarialFactor, "given
- a rating factor entry with key '23' and value '1.345'
- a max_integer_factor_key of '23'
	" do

		subject do
			Products::ActuarialFactors::GroupSizeActuarialFactor.new({
				:actuarial_factor_entries => [
					Products::ActuarialFactors::ActuarialFactorEntry.new({
						:factor_key => '23',
						:factor_value => 1.345
					})
				],
				:max_integer_factor_key => 30
			})
		end

		it "returns the '1.345' for a lookup of 24" do
			expect(subject.lookup(23)).to eq 1.345
		end

	end

	RSpec.describe Products::ActuarialFactors::GroupSizeActuarialFactor, "given
- a rating factor entry with key '1' and value '1.345'
	" do

		subject do
			Products::ActuarialFactors::GroupSizeActuarialFactor.new({
				:actuarial_factor_entries => [
					Products::ActuarialFactors::ActuarialFactorEntry.new({
						:factor_key => '1',
						:factor_value => 1.345
					})
				],
				:max_integer_factor_key => 30
			})
		end

		it "returns the '1.345' for a lookup of 0" do
			expect(subject.lookup(0)).to eq 1.345
		end

		it "returns the '1.345' for a lookup of 0.5" do
			expect(subject.lookup(0.5)).to eq 1.345
		end

	end
end
