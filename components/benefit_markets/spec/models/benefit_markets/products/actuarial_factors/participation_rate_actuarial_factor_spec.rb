require "rails_helper"

module BenefitMarkets
	RSpec.describe Products::ActuarialFactors::ParticipationRateActuarialFactor do
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
	end

	RSpec.describe Products::ActuarialFactors::ParticipationRateActuarialFactor, "given
- a carrier profile
- an active year
- a default factor value
- no rating factor entries
	" do

		let(:default_factor_value) { 1.234567 }
		let(:issuer_profile_id) { BSON::ObjectId.new }
		let(:active_year) { 2015 }

		subject do
			Products::ActuarialFactors::ParticipationRateActuarialFactor.new({
				:default_factor_value => default_factor_value,
				:active_year => active_year,
				:issuer_profile_id => issuer_profile_id
			})
		end

		it "is valid" do
			expect(subject.valid?).to be_truthy
		end

		it "returns the default factor on all lookups" do
			expect(subject.lookup(500)).to eq default_factor_value
			expect(subject.lookup(1)).to eq default_factor_value
			expect(subject.lookup(3.234)).to eq default_factor_value
		end

	end

	RSpec.describe Products::ActuarialFactors::ParticipationRateActuarialFactor, "given
- a rating factor entry with key '11' and value '1.345'
	" do

		subject do
			Products::ActuarialFactors::ParticipationRateActuarialFactor.new({
				:actuarial_factor_entries => [
					Products::ActuarialFactors::ActuarialFactorEntry.new({
						:factor_key => '1',
						:factor_value => 1.345
					})
				]
			})
		end

		it "returns the '1.345' for a lookup of 0" do
			expect(subject.lookup(0)).to eq 1.345
		end

		it "returns the '1.345' for a lookup of 0.49" do
			expect(subject.lookup(0.49)).to eq 1.345
		end

	end

	RSpec.describe Products::ActuarialFactors::ParticipationRateActuarialFactor, "given
- a rating factor entry with key '1' and value '1.345'
	" do

		subject do
			Products::ActuarialFactors::ParticipationRateActuarialFactor.new({
				:actuarial_factor_entries => [
					Products::ActuarialFactors::ActuarialFactorEntry.new({
						:factor_key => '11',
						:factor_value => 1.345
					})
				]
			})
		end

		it "returns the '1.345' for a lookup of 11" do
			expect(subject.lookup(11)).to eq 1.345
		end

		it "returns the '1.345' for a lookup of 11.2" do
			expect(subject.lookup(11.2)).to eq 1.345
		end

	end
end
