require 'rails_helper'

module BenefitSponsors
  module SponsoredBenefits
    RSpec.describe DentalSponsoredBenefit, type: :model, :dbclean => :after_each do

      describe '.verify_elected_choices' do

        subject { described_class.new(params) }

        let(:params) { { product_package_kind: product_package_kind } }

        before do
          expect(subject).to receive(:benefit_sponsor_catalog).and_return(nil)
        end

        context 'when plan option kind is multi_product' do
          let(:product_package_kind) { :multi_product }

          context 'elected_product_choices empty' do
            it 'should fail validation on elected_product_choices' do
              subject.validate
              expect(subject.errors.include?(:elected_product_choices)).to be_truthy
            end
          end

          context 'elected_product_choices present' do
            let(:params) { { product_package_kind: product_package_kind, elected_product_choices: [double] } }

            it 'should pass elected_product_choices validation' do
              subject.validate
              expect(subject.errors.include?(:elected_product_choices)).to be_falsey
            end
          end
        end

        context 'when plan option kind is single_issuer' do
          let(:product_package_kind) { :single_issuer }

          context 'elected_product_choices empty' do
            it 'should not fail validation on elected_product_choices' do
              subject.validate
              expect(subject.errors.include?(:elected_product_choices)).to be_falsey
            end
          end
        end
      end
    end
  end
end
