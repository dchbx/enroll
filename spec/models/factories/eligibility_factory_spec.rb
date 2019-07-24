# frozen_string_literal: true

require 'rails_helper'
require 'pry'
require File.join(Rails.root, 'spec/shared_contexts/ivl_eligibility')

RSpec.describe Factories::EligibilityFactory, type: :model, dbclean: :after_each do

  def reset_premium_tuples
    p_table = @product.premium_tables.first
    p_table.premium_tuples.each { |pt| pt.update_attributes!(cost: pt.age)}
  end

  if Settings.site.faa_enabled
    describe 'cases for multi tax household scenarios' do
      include_context 'setup two tax households with one ia member each'

      let!(:enrollment1) { FactoryBot.create(:hbx_enrollment, :individual_shopping, household: family.active_household, family: family) }
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
          it { expect(@available_eligibility[:csr]).to eq 'csr_100' }
        end

        context 'with an existing enrollment' do
          let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }
          let!(:enrollment2) { FactoryBot.create(:hbx_enrollment, :individual_assisted, applied_aptc_amount: 50.00, household: family.active_household) }
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

      let!(:enrollment1) { FactoryBot.create(:hbx_enrollment, :individual_shopping, household: family.active_household, family: family) }
      let!(:enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment1, applicant_id: family_member.id) }

      before :each do
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

            it { expect(@available_eligibility[:aptc][family_member.id.to_s].round(2)).to eq 443.32 }
            it { expect(@available_eligibility[:total_available_aptc].round(2)).to eq 443.32 }
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
            it { expect(@available_eligibility[:csr]).to eq 'csr_100' }
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

            it { expect(@available_eligibility[:aptc][family_member.id.to_s].round(2)).to eq 225.96 }
            it { expect(@available_eligibility[:aptc][family_member2.id.to_s].round(2)).to eq 274.04 }
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

            it { expect(@available_eligibility[:aptc][family_member.id.to_s].round(2)).to eq 500.00 }
            it { expect(@available_eligibility[:aptc][family_member2.id.to_s].round(2)).to eq 0.00 }
            it { expect(@available_eligibility[:total_available_aptc]).to eq 500.00 }
            it { expect(@available_eligibility[:csr]).to eq 'csr_100' }
          end
        end

        context 'with an existing enrollment' do
          let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }
          let!(:enrollment2) { FactoryBot.create(:hbx_enrollment, :individual_assisted, applied_aptc_amount: 50.00, household: family.active_household, family: family) }
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

            it { expect(@available_eligibility[:aptc][family_member.id.to_s].round(2)).to eq 203.37 }
            it { expect(@available_eligibility[:aptc][family_member2.id.to_s].round(2)).to eq 246.63 }
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

            it { expect(@available_eligibility[:aptc][family_member.id.to_s].round(2)).to eq 450.00 }
            it { expect(@available_eligibility[:aptc][family_member2.id.to_s].round(2)).to eq 0 }
            it { expect(@available_eligibility[:total_available_aptc]).to eq 450.00 }
            it { expect(@available_eligibility[:csr]).to eq 'csr_100' }
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
            end

            it 'should return a Hash' do
              expect(@applicable_aptc.class).to eq Hash
            end

            it 'should return ehb_premium' do
              premium = enrollment1.ivl_decorated_hbx_enrollment.premium_for(enrollment_member1).round
              expect(@applicable_aptc.keys.first).to eq @product_id
              expect(@applicable_aptc.values.first.round).to eq premium
            end
          end

          context 'where selected_aptc less than ehb_premium and available_aptc' do
            before do
              @eligibility_factory = described_class.new(enrollment1.id, 35.00, [@product_id])
              @applicable_aptc = @eligibility_factory.fetch_applicable_aptcs
            end

            it 'should return a Hash' do
              expect(@applicable_aptc.class).to eq Hash
            end

            it 'should return selected_aptc' do
              product_aptc = {@product_id => 35.00}
              expect(@applicable_aptc).to eq product_aptc
            end
          end

          context 'where available_aptc less than ehb_premium and selected_aptc' do
            before do
              family.active_household.tax_households.first.destroy
              @eligibility_factory = described_class.new(enrollment1.id, 100.00, [@product_id])
              @applicable_aptc = @eligibility_factory.fetch_applicable_aptcs
            end

            it 'should return a Hash' do
              expect(@applicable_aptc.class).to eq Hash
            end

            it 'should return selected_aptc' do
              product_aptc = {@product_id => 0.00}
              expect(@applicable_aptc).to eq product_aptc
            end
          end
        end
      end
    end
  end
end
