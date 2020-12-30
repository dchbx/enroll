# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insured::Forms::ProductForm, dbclean: :after_each do
  describe 'new' do
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile, nationwide: nationwide)}
    let(:seralized_product) {Insured::Serializers::ProductSerializer.new(product)}

    context "with product and nationwide true" do
      let(:nationwide) {true}

      subject {Insured::Forms::ProductForm.new(seralized_product)}

      it 'should instantiate a new Product Form' do
        expect(subject).to be_an_instance_of(Insured::Forms::ProductForm)
      end

      it 'should match metal_level_kind' do
        expect(subject.metal_level_kind).to eq product.metal_level_kind.to_s
      end

      it 'should match display_carrier_logo' do
        expect(subject.display_carrier_logo).to eq product.display_carrier_logo
      end

      it 'should populate nationwide' do
        expect(subject.nationwide).to eq product.nationwide
      end

      it 'should match application_period' do
        expect(subject.application_period).to eq product.application_period
      end
    end

    context 'with product and nationwide false' do
      let(:nationwide) {false}

      subject {Insured::Forms::ProductForm.new(seralized_product)}

      it 'should not populate nationwide' do
        expect(subject.nationwide).to eq product.nationwide
      end
    end
  end
end
