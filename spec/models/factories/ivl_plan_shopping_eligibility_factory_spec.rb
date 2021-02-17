# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/ivl_eligibility')

RSpec.describe Factories::IvlPlanShoppingEligibilityFactory do
  before :all do
    # Overcome any timekeeper weirdness.
    # TODO: Find out who the bad citizen is that isn't resetting timekeeper
    #       after playing with it.
    current_year = Date.today.year
    TimeKeeper.set_date_of_record_unprotected!(Date.new(current_year, 3, 4))
  end

  def reset_premium_tuples
    p_table = @product.premium_tables.first
    p_table.premium_tuples.each { |pt| pt.update_attributes!(cost: pt.age)}
  end

  before :each do
    EnrollRegistry[:calculate_monthly_aggregate].feature.stub(:is_enabled).and_return(false)
  end

  unless Settings.site.faa_enabled
    describe 'cases for single tax household scenarios' do
      include_context 'setup one tax household with two ia members'

      let(:current_date) {TimeKeeper.date_of_record.beginning_of_month}
      let!(:enrollment1) { FactoryBot.create(:hbx_enrollment, :individual_shopping, family: family, household: family.active_household, effective_on: current_date) }
      let!(:enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment1, applicant_id: family_member.id, eligibility_date: current_date, coverage_start_on: current_date) }

      before :all do
        @product = FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver, benefit_market_kind: :aca_individual)
        reset_premium_tuples
        benefit_sponsorship = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period).benefit_sponsorship
        benefit_sponsorship.benefit_coverage_periods.each { |bcp| bcp.update_attributes!(slcsp_id: @product.id) }
      end

      context 'for AvailableEligibilityService' do
        context 'for one member enrollment' do
          context 'tax_household exists' do
            before :each do
              @eligibility_factory ||= described_class.new(enrollment1, enrollment1.effective_on)
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
              @eligibility_factory ||= described_class.new(enrollment1, enrollment1.effective_on)
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
              @eligibility_factory ||= described_class.new(enrollment1, enrollment1.effective_on)
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
              @eligibility_factory ||= described_class.new(enrollment1, enrollment1.effective_on)
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
            it { expect(@available_eligibility[:csr]).to eq 'csr_0' }
          end
        end

        context 'with an existing enrollment' do
          let(:current_date) {TimeKeeper.date_of_record.beginning_of_month}
          let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id, eligibility_date: current_date, coverage_start_on: current_date) }
          let!(:enrollment2) { FactoryBot.create(:hbx_enrollment, :individual_assisted, applied_aptc_amount: 50.00, family: family, household: family.active_household, effective_on: current_date) }
          let!(:enrollment_member21) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment2, applicant_id: family_member.id, applied_aptc_amount: 50.00, eligibility_date: current_date, coverage_start_on: current_date) }

          context 'with valid tax household for all the shopping members' do
            before :each do
              @eligibility_factory ||= described_class.new(enrollment1, enrollment1.effective_on)
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
              @eligibility_factory ||= described_class.new(enrollment1, enrollment1.effective_on)
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
              @eligibility_factory = described_class.new(enrollment1, enrollment1.effective_on, 150.00, [@product_id])
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
              @eligibility_factory = described_class.new(enrollment1, enrollment1.effective_on, 35.00, [@product_id])
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

          context 'where available_aptc less than ehb_premium and selected_aptc' do
            before do
              family.active_household.tax_households.first.destroy
              @eligibility_factory = described_class.new(enrollment1, enrollment1.effective_on, 100.00, [@product_id])
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
    end
  end

  after(:all) do
    DatabaseCleaner.clean
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end
end
