require "rails_helper"

module BenefitMarkets
	RSpec.describe Products::ActuarialFactors::CompositeRatingTierActuarialFactor do
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

	RSpec.describe Products::ActuarialFactors::CompositeRatingTierActuarialFactor, "given
- a carrier profile
- an active year
- a default factor value
- no rating factor entries
	" do

		let(:default_factor_value) { 1.234567 }
		let(:issuer_profile_id) { BSON::ObjectId.new }
		let(:active_year) { 2015 }

		subject do
			Products::ActuarialFactors::CompositeRatingTierActuarialFactor.new({
				:default_factor_value => default_factor_value,
				:active_year => active_year,
				:issuer_profile_id => issuer_profile_id
			})
		end

		it "is valid" do
			expect(subject.valid?).to be_truthy
		end

		it "returns the default factor on all lookups" do
			expect(subject.lookup(:bdklajdlfs)).to eq default_factor_value
		end

	end

	RSpec.describe Products::ActuarialFactors::CompositeRatingTierActuarialFactor, "given
- a rating factor entry with key 'abc' and value '1.345'
	" do

		subject do
			Products::ActuarialFactors::CompositeRatingTierActuarialFactor.new({
				:actuarial_factor_entries => [
					Products::ActuarialFactors::ActuarialFactorEntry.new({
						:factor_key => 'abc',
						:factor_value => 1.345
					})
				]
			})
		end

		it "returns the '1.345' for a lookup of 'abc'" do
			expect(subject.lookup('abc')).to eq 1.345
		end

	end
end
