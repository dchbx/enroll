require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::Product, type: :model, dbclean: :after_each do

    let(:this_year)           { TimeKeeper.date_of_record.year }
    let(:benefit_market_kind) { :aca_shop }
    let(:application_period)  { Date.new(this_year, 1, 1)..Date.new(this_year, 12, 31) }
    let(:hbx_id)              { "6262626262" }
    let(:issuer_profile_urn)  { "urn:openhbx:terms:v1:organization:name#safeco" }
    let(:title)               { "SafeCo Active Life $0 Deductable Premier" }
    let(:description)         { "Highest rated and highest value" }
    let(:service_area)        { BenefitMarkets::Locations::ServiceArea.new }

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
          benefit_market_kind:  benefit_market_kind,
          application_period:   application_period,
          hbx_id:               hbx_id,
          # issuer_profile_urn:   issuer_profile_urn,
          title:                title,
          description:          description,
          service_area:         service_area,
          premium_tables:       premium_tables,
        }
    end

    context "A new Product instance" do

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do
        context "that's missing a benefit_market_kind" do
          subject { described_class.new(params.except(:benefit_market_kind)) }

          it "it should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:benefit_market_kind]).to include("can't be blank")
          end
        end

        context "that's missing an application_period" do
          subject { described_class.new(params.except(:application_period)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:application_period]).to include("can't be blank")
          end
        end

        context "that's missing an service_area" do
          subject { described_class.new(params.except(:service_area)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:service_area]).to include("can't be blank")
          end
        end

        # TODO: enable when hbx_id populated in products. validation disabled for now.
        # context "that's missing an hbx_id" do
        #   subject { described_class.new(params.except(:hbx_id)) }

        #   it "should be invalid" do
        #     subject.validate
        #     expect(subject).to_not be_valid
        #     expect(subject.errors[:hbx_id]).to include("can't be blank")
        #   end
        # end

        context "that's missing a title" do
          subject { described_class.new(params.except(:title)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:title]).to include("can't be blank")
          end
        end
      end

      context "with invalid arguments" do
        context "and benefit_market_kind is invalid" do
          let(:invalid_benefit_market_kind)  { :flea_market }

          subject { described_class.new(params.except(:benefit_market_kind).merge({benefit_market_kind: invalid_benefit_market_kind})) }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:benefit_market_kind]).to include("#{invalid_benefit_market_kind} is not a valid benefit market kind")
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


    context "Comparing Products" do
      let(:base_product)      { described_class.new(**params) }

      context "and they are the same" do
        let(:compare_product) { described_class.new(**params) }

        it "they should be different instances" do
          expect(base_product.id).to_not eq compare_product.id
        end

        it "should match" do
          expect(base_product <=> compare_product).to eq 0
        end
      end

      context "and the attributes are different" do
        let(:compare_product)              { described_class.new(**params) }

        before { compare_product.benefit_market_kind = :aca_individual }

        it "should not match" do
          expect(base_product).to_not eq compare_product
        end

        it "the base_product should be less than the compare_product" do
          expect(base_product <=> compare_product).to eq(-1)
        end
      end

      context "and the premium_tables are different" do
        let(:compare_product)   { described_class.new(**params) }
        let(:new_premium_table) { FactoryGirl.build(:benefit_markets_products_premium_table) }

        before { compare_product.premium_tables << new_premium_table }

        it "should not match" do
          expect(base_product).to_not eq compare_product
        end

        it "the base_product should be lest than the compare_product" do
          expect(base_product <=> compare_product).to eq(-1)
        end
      end
    end


    context "Given a Product with out-of-date PremiumTables" do
      let(:quarter_2)           { Date.new(this_year, 4, 1)..Date.new(this_year, 6, 30) }
      let(:q1_effective_date)   { quarter_1.begin + 2.months }
      let(:q2_effective_date)   { quarter_2.begin + 1.month }

      subject { described_class.new(params) }

      it "should have a premium_table for initial effective_period" do
        expect(subject.premium_table_effective_on(q1_effective_date)).to eq premium_table_q1
      end

      it "should not have a premium table for new effective_period" do
        expect(subject.premium_table_effective_on(q2_effective_date)).to eq nil
      end

      context "and a premium_table is added" do
        let(:premium_q2_age_20)   { BenefitMarkets::Products::PremiumTuple.new(age: 20, cost: 202) }
        let(:premium_q2_age_30)   { BenefitMarkets::Products::PremiumTuple.new(age: 30, cost: 302) }
        let(:premium_q2_age_40)   { BenefitMarkets::Products::PremiumTuple.new(age: 40, cost: 402) }
        let(:premium_table_q2)    { BenefitMarkets::Products::PremiumTable.new(
                                      effective_period: quarter_2,
                                      rating_area: rating_area,
                                      premium_tuples: [premium_q2_age_20, premium_q2_age_30, premium_q2_age_40],
                                    ) }

        before { subject.add_premium_table(premium_table_q2) }

        it "should have a premium table for the new effective_period" do
          expect(subject.premium_table_effective_on(q2_effective_date)).to eq premium_table_q2
        end


        context "and a premium_table already exists for the effective_period" do

          it "should throw an error" do
            expect{subject.add_premium_table(premium_table_q1)}.to raise_error(BenefitMarkets::DuplicatePremiumTableError)
          end
        end

        context "and the premium_table effective_period isn't covered by the product application_period" do
          let(:out_of_range_effective_period) { Date.new(this_year + 1, 1, 1)..Date.new(this_year + 1, 3, 31) }
          let(:invalid_premium_table)         { BenefitMarkets::Products::PremiumTable.new(
                                                  effective_period: out_of_range_effective_period,
                                                  rating_area: rating_area,
                                                  premium_tuples: [premium_q2_age_20, premium_q2_age_30, premium_q2_age_40],
                                                ) }

          it "should throw an error" do
            expect{subject.add_premium_table(invalid_premium_table)}.to raise_error(BenefitMarkets::InvalidEffectivePeriodError)
          end
        end
      end

      context "and a premium_table is updated" do
        let(:premium_q2_age_20)         { BenefitMarkets::Products::PremiumTuple.new(age: 20, cost: 203) }
        let(:premium_q2_age_30)         { BenefitMarkets::Products::PremiumTuple.new(age: 30, cost: 303) }
        let(:premium_q2_age_40)         { BenefitMarkets::Products::PremiumTuple.new(age: 40, cost: 403) }
        let(:updated_premium_table_q2)  { BenefitMarkets::Products::PremiumTable.new(
                                            effective_period: quarter_2,
                                            rating_area: rating_area,
                                            premium_tuples: [premium_q2_age_20, premium_q2_age_30, premium_q2_age_40],
                                          ) }
        let(:effective_date_q2)         { updated_premium_table_q2.effective_period.min }

        it "should replace the existing premium_table" do
          subject.update_premium_table(updated_premium_table_q2)
          expect(subject.premium_table_effective_on(effective_date_q2).premium_tuples).to include(premium_q2_age_30)
        end

        context "and a premium_table doesn't exist for the effective_period" do
          let(:quarter_3)                 { Date.new(this_year, 7, 1)..Date.new(this_year, 9, 30) }
          let(:premium_q3_age_20)         { BenefitMarkets::Products::PremiumTuple.new(age: 20, cost: 204) }
          let(:premium_q3_age_30)         { BenefitMarkets::Products::PremiumTuple.new(age: 30, cost: 304) }
          let(:premium_q3_age_40)         { BenefitMarkets::Products::PremiumTuple.new(age: 40, cost: 404) }
          let(:premium_table_q3)          { BenefitMarkets::Products::PremiumTable.new(
                                              effective_period: quarter_3,
                                              rating_area: rating_area,
                                              premium_tuples: [premium_q3_age_20, premium_q3_age_30, premium_q3_age_40],
                                            ) }

          let(:effective_date_q3)         { premium_table_q3.effective_period.min }

          it "should add the updated premium_table" do
            subject.update_premium_table(premium_table_q3)
            expect(subject.premium_table_effective_on(effective_date_q3).premium_tuples).to include(premium_q3_age_30)
          end
        end
      end

    end



    context "An open file in SERFF template format" do
      context "and the contents are Qualified Health Plans" do
      end

      context "and the contents are QHP service areas" do
      end

      context "and the contents are QHP rate tables" do
      end

      context "and the contents are Qualified Dental Plans" do
      end

      context "and the contents are QDP rate tables" do
      end
    end


  end
end
