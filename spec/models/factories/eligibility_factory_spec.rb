# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/ivl_eligibility')

RSpec.describe Factories::EligibilityFactory, type: :model do

  before :all do
    DatabaseCleaner.clean
  end

  def reset_premium_tuples
    p_table = @product.premium_tables.first
    p_table.premium_tuples.each { |pt| pt.update_attributes!(cost: pt.age)}
  end

  if Settings.site.faa_enabled
    describe 'cases for multi tax household scenarios' do
      include_context 'setup two tax households with one ia member each'

      let!(:enrollment1) { FactoryBot.create(:hbx_enrollment, :individual_shopping, family: family, household: family.active_household) }
      let!(:enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment1, applicant_id: family_member.id) }

      before :each do
        @product = FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver, benefit_market_kind: :aca_individual)
        benefit_sponsorship = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period).benefit_sponsorship
        benefit_sponsorship.benefit_coverage_periods.each { |bcp| bcp.update_attributes!(slcsp_id: @product.id) }
      end

      context 'for AvailableEligibilityService' do
        context 'for one member enrollment' do
          before :each do
            @eligibility_factory ||= described_class.new(enrollment1.id)
            @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
          end

          it 'should return a Hash' do
            expect(@available_eligibility.class).to eq Hash
          end

          [:aptc, :csr, :total_available_aptc].each do |keyy|
            it { expect(@available_eligibility.key?(keyy)).to be_truthy }
          end

          it 'should have all the aptc shopping member ids' do
            aptc_keys = @available_eligibility[:aptc].keys
            enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
              expect(aptc_keys).to include(member_id.to_s)
            end
          end

          it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 100.00 }
          it { expect(@available_eligibility[:total_available_aptc]).to eq 100.00 }
          it { expect(@available_eligibility[:csr]).to eq 'csr_87' }
        end

        context 'for two members enrollment from two tax households' do
          let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }

          before :each do
            @eligibility_factory ||= described_class.new(enrollment1.id)
            @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
          end

          it 'should return a Hash' do
            expect(@available_eligibility.class).to eq Hash
          end

          [:aptc, :csr, :total_available_aptc].each do |keyy|
            it { expect(@available_eligibility.key?(keyy)).to be_truthy }
          end

          it 'should have all the aptc shopping member ids' do
            aptc_keys = @available_eligibility[:aptc].keys
            enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
              expect(aptc_keys).to include(member_id.to_s)
            end
          end

          it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 100.00 }
          it { expect(@available_eligibility[:aptc][family_member2.id.to_s]).to eq 200.0 }
          it { expect(@available_eligibility[:total_available_aptc]).to eq 300.00 }
          it { expect(@available_eligibility[:csr]).to eq 'csr_87' }
        end

        context 'for two members enrollment from two tax households with one medicaid member' do
          let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }

          before :each do
            tax_household_member.update_attributes!(is_ia_eligible: false, is_medicaid_chip_eligible: true)
            @eligibility_factory ||= described_class.new(enrollment1.id)
            @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
          end

          it 'should return a Hash' do
            expect(@available_eligibility.class).to eq Hash
          end

          [:aptc, :csr, :total_available_aptc].each do |keyy|
            it { expect(@available_eligibility.key?(keyy)).to be_truthy }
          end

          it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 100.00 }
          it { expect(@available_eligibility[:total_available_aptc]).to eq 100.00 }
          it { expect(@available_eligibility[:csr]).to eq 'csr_0' }
        end

        context 'with an existing enrollment' do
          let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }
          let!(:enrollment2) { FactoryBot.create(:hbx_enrollment, :individual_assisted, applied_aptc_amount: 50.00, family: family, household: family.active_household) }
          let!(:enrollment_member21) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment2, applicant_id: family_member.id, applied_aptc_amount: 50.00) }

          before :each do
            @eligibility_factory ||= described_class.new(enrollment1.id)
            @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
          end

          it 'should return a Hash' do
            expect(@available_eligibility.class).to eq Hash
          end

          [:aptc, :csr, :total_available_aptc].each do |keyy|
            it { expect(@available_eligibility.key?(keyy)).to be_truthy }
          end

          it 'should have all the aptc shopping member ids' do
            aptc_keys = @available_eligibility[:aptc].keys
            enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
              expect(aptc_keys).to include(member_id.to_s)
            end
          end

          it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 50.00 }
          it { expect(@available_eligibility[:aptc][family_member2.id.to_s]).to eq 200.0 }
          it { expect(@available_eligibility[:total_available_aptc]).to eq 250.00 }
          it { expect(@available_eligibility[:csr]).to eq 'csr_87' }
        end
      end

      context 'for ApplicableAptcService' do
        context 'for one member enrollment' do
          before :each do
            allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
            enrollment1.update_attributes!(product_id: @product.id, aasm_state: 'coverage_selected', consumer_role_id: person.consumer_role.id)
          end

          context 'for ehb_premium less than selected_aptc' do
            before do
              @eligibility_factory = described_class.new(enrollment1.id, 150.00)
              @applicable_aptc = @eligibility_factory.fetch_applicable_aptc
            end

            it 'should return ehb_premium' do
              expect(@applicable_aptc.round).to eq enrollment_member1.age_on_effective_date.round
            end
          end

          context 'for selected_aptc less than ehb_premium' do
            before do
              @eligibility_factory = described_class.new(enrollment1.id, 35.00)
              @applicable_aptc = @eligibility_factory.fetch_applicable_aptc
            end

            it 'should return selected_aptc' do
              expect(@applicable_aptc.round).to eq 35.00
            end
          end
        end
      end
    end
  end

  unless Settings.site.faa_enabled
    describe 'cases for single tax household scenarios' do
      include_context 'setup one tax household with two ia members'

      let!(:enrollment1) { FactoryBot.create(:hbx_enrollment, :individual_shopping, household: family.active_household, family: family, effective_on: Date.today.beginning_of_year) }
      let!(:enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment1, applicant_id: family_member.id) }

      before :all do
        current_year = Date.today.year
        TimeKeeper.set_date_of_record_unprotected!(Date.new(current_year, 3, 4))
        @product = FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver, benefit_market_kind: :aca_individual)
        reset_premium_tuples
        benefit_sponsorship = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period).benefit_sponsorship
        benefit_sponsorship.benefit_coverage_periods.each { |bcp| bcp.update_attributes!(slcsp_id: @product.id) }
      end

      context 'for AvailableEligibilityService' do
        context 'for one member enrollment' do
          context 'tax_household exists' do
            before :each do
              @eligibility_factory ||= described_class.new(enrollment1.id)
              @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
            end

            it 'should return a Hash' do
              expect(@available_eligibility.class).to eq Hash
            end

            [:aptc, :csr, :total_available_aptc].each do |keyy|
              it { expect(@available_eligibility.key?(keyy)).to be_truthy }
            end

            it 'should have all the aptc shopping member ids' do
              aptc_keys = @available_eligibility[:aptc].keys
              enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
                expect(aptc_keys).to include(member_id.to_s)
              end
            end

            it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 443.33 }
            it { expect(@available_eligibility[:total_available_aptc]).to eq 443.33 }
            it { expect(@available_eligibility[:csr]).to eq 'csr_94' }
          end

          context 'tax_household does not exists' do
            before :each do
              family.active_household.tax_households = []
              family.active_household.save!
              @eligibility_factory ||= described_class.new(enrollment1.id)
              @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
            end

            it 'should return a Hash' do
              expect(@available_eligibility.class).to eq Hash
            end

            [:aptc, :csr, :total_available_aptc].each do |keyy|
              it { expect(@available_eligibility.key?(keyy)).to be_truthy }
            end

            it 'should have all the aptc shopping member ids' do
              aptc_keys = @available_eligibility[:aptc].keys
              enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
                expect(aptc_keys).to include(member_id.to_s)
              end
            end

            it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 0.00 }
            it { expect(@available_eligibility[:total_available_aptc]).to eq 0.00 }
            it { expect(@available_eligibility[:csr]).to eq 'csr_0' }
          end
        end

        context 'for two members enrollment' do
          let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }

          context 'with valid tax household for all the shopping members' do
            before :each do
              @eligibility_factory ||= described_class.new(enrollment1.id)
              @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
            end

            it 'should return a Hash' do
              expect(@available_eligibility.class).to eq Hash
            end

            [:aptc, :csr, :total_available_aptc].each do |keyy|
              it { expect(@available_eligibility.key?(keyy)).to be_truthy }
            end

            it 'should have all the aptc shopping member ids' do
              aptc_keys = @available_eligibility[:aptc].keys
              enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
                expect(aptc_keys).to include(member_id.to_s)
              end
            end

            it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 225.96711798839456 }
            it { expect(@available_eligibility[:aptc][family_member2.id.to_s]).to eq 274.0328820116054 }
            it { expect(@available_eligibility[:total_available_aptc]).to eq 500.00 }
            it { expect(@available_eligibility[:csr]).to eq 'csr_94' }
          end

          context 'without valid tax household for all the shopping members' do
            before :each do
              family.active_household.tax_households.first.tax_household_members.second.destroy
              @eligibility_factory ||= described_class.new(enrollment1.id)
              @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
            end

            it 'should return a Hash' do
              expect(@available_eligibility.class).to eq Hash
            end

            [:aptc, :csr, :total_available_aptc].each do |keyy|
              it { expect(@available_eligibility.key?(keyy)).to be_truthy }
            end

            it 'should have all the aptc shopping member ids' do
              aptc_keys = @available_eligibility[:aptc].keys
              enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
                expect(aptc_keys).to include(member_id.to_s)
              end
            end

            it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 500.00 }
            it { expect(@available_eligibility[:aptc][family_member2.id.to_s]).to eq 0.00 }
            it { expect(@available_eligibility[:total_available_aptc]).to eq 500.00 }
            it { expect(@available_eligibility[:csr]).to eq 'csr_0' }
          end
        end

        context 'with an existing enrollment' do
          let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }
          let!(:enrollment2) { FactoryBot.create(:hbx_enrollment, :individual_assisted, applied_aptc_amount: 50.00, household: family.active_household, family: family, effective_on: Date.today.beginning_of_year) }
          let!(:enrollment_member21) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment2, applicant_id: family_member.id, applied_aptc_amount: 50.00) }

          context 'with valid tax household for all the shopping members' do
            before :each do
              @eligibility_factory ||= described_class.new(enrollment1.id)
              @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
            end

            it 'should return a Hash' do
              expect(@available_eligibility.class).to eq Hash
            end

            [:aptc, :csr, :total_available_aptc].each do |keyy|
              it { expect(@available_eligibility.key?(keyy)).to be_truthy }
            end

            it 'should have all the aptc shopping member ids' do
              aptc_keys = @available_eligibility[:aptc].keys
              enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
                expect(aptc_keys).to include(member_id.to_s)
              end
            end

            it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 203.3704061895551 }
            it { expect(@available_eligibility[:aptc][family_member2.id.to_s]).to eq 246.62959381044487 }
            it { expect(@available_eligibility[:total_available_aptc]).to eq 450.00 }
            it { expect(@available_eligibility[:csr]).to eq 'csr_94' }
          end

          context 'without valid tax household for all the shopping members' do
            before :each do
              family.active_household.tax_households.first.tax_household_members.second.destroy
              @eligibility_factory ||= described_class.new(enrollment1.id)
              @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
            end

            it 'should return a Hash' do
              expect(@available_eligibility.class).to eq Hash
            end

            [:aptc, :csr, :total_available_aptc].each do |keyy|
              it { expect(@available_eligibility.key?(keyy)).to be_truthy }
            end

            it 'should have all the aptc shopping member ids' do
              aptc_keys = @available_eligibility[:aptc].keys
              enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
                expect(aptc_keys).to include(member_id.to_s)
              end
            end

            it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 450.00 }
            it { expect(@available_eligibility[:aptc][family_member2.id.to_s]).to eq 0 }
            it { expect(@available_eligibility[:total_available_aptc]).to eq 450.00 }
            it { expect(@available_eligibility[:csr]).to eq 'csr_0' }
          end
        end
      end

      context 'for ApplicableAptcService' do
        context 'for one member enrollment' do
          before :each do
            @product_id = @product.id.to_s
            allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
            enrollment1.update_attributes!(product_id: @product.id, aasm_state: 'coverage_selected', consumer_role_id: person.consumer_role.id)
          end

          context 'where ehb_premium less than selected_aptc and available_aptc' do
            before do
              @eligibility_factory = described_class.new(enrollment1.id, 150.00, [@product_id])
              @applicable_aptc = @eligibility_factory.fetch_applicable_aptcs
              @aptc_per_member = @eligibility_factory.fetch_aptc_per_member
              @ehb_premium = @eligibility_factory.send(:total_ehb_premium, enrollment1.product.id)
            end

            context '.fetch_applicable_aptcs' do
              it 'should return a Hash' do
                expect(@applicable_aptc.class).to eq Hash
              end

              it 'should return ehb_premium' do
                expect(@applicable_aptc.keys.first).to eq @product_id
                expect(@applicable_aptc.values.first).to eq @ehb_premium
              end
            end

            context '.fetch_aptc_per_member' do
              it 'should return a Hash' do
                expect(@aptc_per_member.class).to eq Hash
              end

              it 'should should return ehb premium' do
                fm1_id = enrollment1.hbx_enrollment_members.first.applicant_id.to_s
                expect(@aptc_per_member[enrollment1.product_id.to_s][fm1_id]).to eq @ehb_premium
              end
            end
          end

          context 'where selected_aptc less than ehb_premium and available_aptc' do
            before do
              @eligibility_factory = described_class.new(enrollment1.id, 35.00, [@product_id])
              @applicable_aptc = @eligibility_factory.fetch_applicable_aptcs
              @aptc_per_member = @eligibility_factory.fetch_aptc_per_member
            end

            context '.fetch_applicable_aptcs' do
              it 'should return a Hash' do
                expect(@applicable_aptc.class).to eq Hash
              end

              it 'should return selected_aptc' do
                expect(@applicable_aptc[@product_id]).to eq 35.00
              end
            end

            context '.fetch_aptc_per_member' do
              it 'should return a Hash' do
                expect(@aptc_per_member.class).to eq Hash
              end

              it 'should return selected_aptc' do
                fm1_id = enrollment1.hbx_enrollment_members.first.applicant_id.to_s
                expect(@aptc_per_member[enrollment1.product_id.to_s][fm1_id]).to eq 35.00
              end
            end
          end

          context 'available aptc for catastrophic product' do
            before do
              @product = FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :catastrophic, benefit_market_kind: :aca_individual)
              @product_id = @product.id.to_s
              @eligibility_factory = described_class.new(enrollment1.id, 35.00, [@product_id])
              @applicable_aptc = @eligibility_factory.fetch_applicable_aptcs
              @aptc_per_member = @eligibility_factory.fetch_aptc_per_member
            end

            context '.fetch_applicable_aptcs' do
              it 'should return a Hash' do
                expect(@applicable_aptc.class).to eq Hash
              end

              it 'should return zero aptc' do
                expect(@applicable_aptc[@product_id]).to eq 0.0
              end
            end

            context '.fetch_aptc_per_member' do
              it 'should return a Hash' do
                expect(@aptc_per_member.class).to eq Hash
              end

              it 'should return zero aptc' do
                fm1_id = enrollment1.hbx_enrollment_members.first.applicant_id.to_s
                expect(@aptc_per_member[@product_id][fm1_id]).to eq 0.0
              end
            end
          end

          context 'available aptc for dental product' do
            before do
              @product = FactoryBot.create(:benefit_markets_products_dental_products_dental_product, benefit_market_kind: :aca_individual)
              @product_id = @product.id.to_s
              @eligibility_factory = described_class.new(enrollment1.id, 35.00, [@product_id])
              @applicable_aptc = @eligibility_factory.fetch_applicable_aptcs
            end

            context '.fetch_applicable_aptcs' do
              it 'should return a Hash' do
                expect(@applicable_aptc.class).to eq Hash
              end

              it 'should not apply aptc for dental product' do
                expect(@applicable_aptc[@product_id]).to eq 0.0
              end
            end
          end

          context 'where available_aptc less than ehb_premium and selected_aptc' do
            before do
              family.active_household.tax_households.first.destroy
              @eligibility_factory = described_class.new(enrollment1.id, 100.00, [@product_id])
              @applicable_aptc = @eligibility_factory.fetch_applicable_aptcs
              @aptc_per_member = @eligibility_factory.fetch_aptc_per_member
            end

            context '.fetch_applicable_aptcs' do
              it 'should return a Hash' do
                expect(@applicable_aptc.class).to eq Hash
              end

              it 'should return available_aptc' do
                expect(@applicable_aptc[@product_id]).to eq 0.00
              end
            end

            context '.fetch_aptc_per_member' do
              it 'should return a Hash' do
                expect(@applicable_aptc.class).to eq Hash
              end

              it 'should return available_aptc' do
                fm1_id = enrollment1.hbx_enrollment_members.first.applicant_id.to_s
                expect(@aptc_per_member[enrollment1.product_id.to_s][fm1_id]).to eq 0.00
              end
            end
          end
        end
      end

      context '#fetch_member_level_applicable_aptcs' do
        let(:applicable_aptc) { 300.00 }

        context 'with one enrollment member' do
          before :each do
            @eligibility_factory ||= described_class.new(enrollment1.id)
            @member_level_aptcs ||= @eligibility_factory.fetch_member_level_applicable_aptcs(applicable_aptc)
          end
          it 'should return the ratio hash for 1 enrollment member' do
            ratio_hash = {}
            ratio_hash[family_member.id.to_s] = applicable_aptc
            expect(@member_level_aptcs).to eq ratio_hash
          end
        end

        context 'with two enrollment members' do
          let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }

          before :each do
            person.update_attributes(dob: TimeKeeper.date_of_record - 40.years)
            person2.update_attributes(dob: TimeKeeper.date_of_record - 40.years)
            @eligibility_factory ||= described_class.new(enrollment1.id)
            @member_level_aptcs ||= @eligibility_factory.fetch_member_level_applicable_aptcs(applicable_aptc)
          end

          it 'should return ratio hash for 2 enrollment members' do
            ratio_hash = {}
            ratio_hash[family_member.id.to_s] = applicable_aptc / 2
            ratio_hash[family_member2.id.to_s] = applicable_aptc / 2
            expect(@member_level_aptcs).to eq ratio_hash
          end
        end
      end

      context 'for two members enrollment' do
        before :each do
          @product_id = @product.id.to_s
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
          enrollment.update_attributes!(product_id: @product.id, aasm_state: 'coverage_selected', consumer_role_id: person.consumer_role.id)
        end

        let(:current_date) {TimeKeeper.date_of_record.beginning_of_month}
        let!(:member2) {FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment, applicant_id: family_member2.id, eligibility_date: current_date, coverage_start_on: current_date)}
        let!(:enrollment) {FactoryBot.create(:hbx_enrollment, :individual_assisted, family: family, household: family.active_household, effective_on: current_date)}
        let!(:member1) {FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment, applicant_id: family_member.id, eligibility_date: current_date, coverage_start_on: current_date)}

        context 'for fetch_elected_aptc_per_member' do

          context '.fetch_elected_aptc_per_member' do
            it 'should return a Hash of members aptc' do
              eligibility_factory = described_class.new(enrollment.id, 150.00, [@product_id])
              elected_aptc_per_member = eligibility_factory.fetch_elected_aptc_per_member
              expect(elected_aptc_per_member.class).to eq Hash
              expect(elected_aptc_per_member.values[0]).to eq 82.20986460348162
              expect(elected_aptc_per_member.values[1]).to eq 67.79013539651837
            end

            it 'should raise error for nil value' do
              eligibility_factory = described_class.new(enrollment.id, nil, [@product_id])
              expect {eligibility_factory.fetch_elected_aptc_per_member}.to raise_error(RuntimeError, /Cannot process without selected_aptc/)
            end
          end
        end

        context 'for fetch_max_aptc' do
          context '.fetch_max_aptc' do
            it 'should return max aptc' do
              eligibility_factory = described_class.new(enrollment.id)
              max_aptc = eligibility_factory.fetch_max_aptc
              expect(max_aptc).to eq 500.0
            end
          end
        end
      end

      after(:all) do
        DatabaseCleaner.clean
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end
    end
  end
end
