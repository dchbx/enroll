require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::HealthProducts::HealthProduct, type: :model do

    let(:this_year)               { TimeKeeper.date_of_record.year }
    let(:benefit_market_kind)     { :aca_shop }
    let(:application_period)      { Date.new(this_year, 1, 1)..Date.new(this_year, 12, 31) }

    let(:hbx_id)                  { "6262626262" }
    let(:issuer_profile_urn)      { "urn:openhbx:terms:v1:organization:name#safeco" }
    let(:title)                   { "SafeCo Active Life $0 Deductable Premier" }
    let(:description)             { "Highest rated and highest value" }
    let(:service_area)            { BenefitMarkets::Locations::ServiceArea.new }

    let(:hios_id)                 { "86052DC0400001-01" }
    let(:hios_base_id)            { "86052DC0400001" }
    let(:csr_variant_id)          { "01" }

    let(:health_plan_kind)        { :pos }
    let(:metal_level_kind)        { :silver }
    let(:ehb)                     { 0.9 }
    let(:is_standard_plan)        { false }
    let(:provider_directory_url)  { "http://example.com/providers" }
    let(:rx_formulary_url)        { "http://example.com/formularies/1" }

    let(:sbc_document)            { Object.new }

    let(:rating_area)         { BenefitMarkets::Locations::RatingArea.new }
    let(:quarter_1)           { Date.new(this_year, 1, 1)..Date.new(this_year, 3, 31) }
    let(:premium_q1_age_20)   { BenefitMarkets::Products::PremiumTuple.new(age: 20, cost: 201) }
    let(:premium_q1_age_30)   { BenefitMarkets::Products::PremiumTuple.new(age: 30, cost: 301) }
    let(:premium_q1_age_40)   { BenefitMarkets::Products::PremiumTuple.new(age: 40, cost: 401) }
    let(:premium_table_q1)    { BenefitMarkets::Products::PremiumTable.new(
                                  effective_period: quarter_1,
                                  rating_area: rating_area,
                                  premium_tuples: [premium_q1_age_20, premium_q1_age_30, premium_q1_age_40],
                                ) }
    let(:premium_tables)      { [premium_table_q1] }


    let(:params) do 
      {
        benefit_market_kind:      benefit_market_kind,
        application_period:       application_period,
        hbx_id:                   hbx_id,
        # issuer_profile_urn:       issuer_profile_urn,
        title:                    title,
        description:              description,
        service_area:             service_area,
        premium_tables:           premium_tables,

        hios_id:                  hios_id,
        hios_base_id:             hios_base_id,
        csr_variant_id:           csr_variant_id,
        health_plan_kind:         health_plan_kind,
        metal_level_kind:         metal_level_kind,
        ehb:                      ehb,
        is_standard_plan:         is_standard_plan,
        provider_directory_url:   provider_directory_url,
        rx_formulary_url: rx_formulary_url,

        # renewal_product: renewal_product,
        # catastrophic_age_off_product: catastrophic_age_off_product,
        # sbc_document: sbc_document,
      }
    end

    context "A new HealthProduct instance" do

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do

        context "that's missing hios_id" do
          subject { described_class.new(params.except(:hios_id)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:hios_id]).to include("can't be blank")
          end
        end

        context "that's missing health_plan_kind" do
          subject { described_class.new(params.except(:health_plan_kind)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:health_plan_kind]).to include("can't be blank")
          end
        end
      end

      context "with invalid params" do
        context "and benefit_market_kind is invalid" do
          let(:invalid_metal_level_kind)  { :copper }

          subject { described_class.new(params.except(:metal_level_kind).merge({metal_level_kind: invalid_metal_level_kind})) }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:metal_level_kind]).to include("#{invalid_metal_level_kind} is not a valid metal level kind")
          end
        end

        context "and ehb is invalid" do
          let(:invalid_ehb)  { 0.0 }

          subject { described_class.new(params.except(:ehb).merge({ehb: invalid_ehb})) }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:ehb]).to include("must be greater than 0.0")
          end
        end
      end

      context "with all valid params" do
        subject { described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end
      end

    end




  end
end
