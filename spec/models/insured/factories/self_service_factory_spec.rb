# frozen_string_literal: true

require 'rails_helper'

module Insured
  RSpec.describe Factories::SelfServiceFactory, type: :model, dbclean: :after_each do

    before :each do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
      DatabaseCleaner.clean
    end

    let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let(:sep) {FactoryBot.create(:special_enrollment_period, family: family)}
    let(:sbc_document) {FactoryBot.build(:document, subject: 'SBC', identifier: 'urn:openhbx#123')}
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, title: 'AAA', issuer_profile_id: 'ab1233', metal_level_kind: :silver, benefit_market_kind: :aca_individual, sbc_document: sbc_document)}
    let!(:enrollment) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, consumer_role_id: person.consumer_role.id)}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record, hbx_enrollment: enrollment, coverage_start_on: TimeKeeper.date_of_record)}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: enrollment)}
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}

    subject { Insured::Factories::SelfServiceFactory }

    describe "view methods" do
      before :each do
        @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual, metal_level_kind: {"$ne" => "catastrophic"}).first
        @product.update_attributes(ehb: 0.9844)
        enrollment.update_attributes(product: @product)
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 59, 'R-DC001').and_return(814.85)
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 60, 'R-DC001').and_return(846.72)
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 61, 'R-DC001').and_return(879.8)
        person.update_attributes!(dob: (enrollment.effective_on - 61.years))
        family.family_members.detect { |fm| !fm.is_primary_applicant }.person.update_attributes!(dob: (enrollment.effective_on - 59.years))
      end

      context "#find" do
        before :each do
          family.special_enrollment_periods << sep
          @enrollment_id = enrollment.id
          @family_id     = family.id
          @qle           = QualifyingLifeEventKind.find(BSON::ObjectId.from_string(sep.qualifying_life_event_kind_id))
        end

        it "returns a hash of valid params" do
          @form_params = subject.find(@enrollment_id, @family_id)
          expect(@form_params[:enrollment]).to eq enrollment
          expect(@form_params[:family]).to eq family
          expect(@form_params[:qle]).to eq @qle
        end

        it "returns a falsey is_aptc_eligible if latest_active_tax_household does not exist" do
          @form_params = subject.find(@enrollment_id, @family_id)
          expect(@form_params[:is_aptc_eligible]).to be_falsey
        end

        it "returns a truthy is_aptc_eligible if tax household and valid aptc members exist" do
          tax_household = FactoryBot.create(:tax_household, household: family.active_household)
          FactoryBot.create(:tax_household_member, tax_household: tax_household)
          form_params = subject.find(@enrollment_id, @family_id)
          expect(form_params[:is_aptc_eligible]).to be_truthy
        end
      end
    end

    describe "post methods" do
      before :all do
        DatabaseCleaner.clean
      end

      let(:sep) { FactoryBot.create(:special_enrollment_period, family: family) }
      let(:sbc_document) { FactoryBot.build(:document, subject: "SBC", identifier: "urn:openhbx#123") }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, title: "AAA", metal_level_kind: :silver, issuer_profile_id: "ab1233", sbc_document: sbc_document) }
      let(:enrollment_to_cancel) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today + 1.month) }
      let(:enrollment_to_term) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today - 1.month) }

      context "#term_or_cancel" do
        it "should cancel an enrollment if it is not yet effective" do
          subject.term_or_cancel(enrollment_to_cancel.id, TimeKeeper.date_of_record, 'cancel')
          enrollment_to_cancel.reload
          expect(enrollment_to_cancel.aasm_state).to eq 'coverage_canceled'
        end

        it "should terminate an enrollment if it is already effective" do
          subject.term_or_cancel(enrollment_to_term.id, TimeKeeper.date_of_record, 'terminate')
          enrollment_to_term.reload
          expect(enrollment_to_term.aasm_state).to eq 'coverage_terminated'
        end
      end
    end

    describe "update_enrollment_for_apcts" do
      let!(:tax_household10) {FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil)}
      let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000)}
      let!(:tax_household_member1) {tax_household10.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
      let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)}


      before :each do
        @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
        @product.update_attributes(ehb: 0.9844)
        premium_table = @product.premium_tables.first
        premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 614.85)
        premium_table.premium_tuples.where(age: 60).first.update_attributes(cost: 646.72)
        premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 679.8)
        @product.save!
        enrollment.update_attributes(product: @product, effective_on: TimeKeeper.date_of_record)
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 59, 'R-DC001').and_return(614.85)
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 60, 'R-DC001').and_return(646.72)
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 61, 'R-DC001').and_return(679.8)
        person.update_attributes!(dob: (enrollment.effective_on - 61.years))
        family.family_members[1].person.update_attributes!(dob: (enrollment.effective_on - 59.years))
      end

      it 'should return updated enrollment with aptc fields' do
        subject.update_enrollment_for_apcts(enrollment, 2000)
        enrollment.reload
        expect(enrollment.applied_aptc_amount.to_f).to eq 1274.44
      end
    end
    # rubocop:disable Lint/UselessAssignment
    describe "update enrollment for renewing enrollments" do

      before :each do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 12, 15))
        effective_on = hbx_profile.benefit_sponsorship.current_benefit_period.start_on
        tax_household10 = FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil, effective_starting_on: hbx_profile.benefit_sponsorship.current_benefit_period.start_on)
        eligibility_determination = FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000, determined_on: hbx_profile.benefit_sponsorship.current_benefit_period.start_on)
        tax_household_member1 = tax_household10.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)
        tax_household_member2 = tax_household10.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)

        @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
        @product.update_attributes(ehb: 0.9844, application_period: Date.new(effective_on.year, 1, 1)..Date.new(effective_on.year, 1, 1).end_of_year)
        premium_table = @product.premium_tables.first
        premium_table.update_attributes(effective_period: Date.new(effective_on.year, 1, 1)..Date.new(effective_on.year, 1, 1).end_of_year)
        @product.save!
        enrollment.update_attributes(product: @product, effective_on: effective_on, aasm_state: "auto_renewing")
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, effective_on, person.age_on(Date.today), 'R-DC001').and_return(679.8)
      end

      it 'should return the updated enrollment' do
        subject.update_aptc(enrollment.id, 1000)
        enrollment.reload
        family.reload
        expect(enrollment.aasm_state).to eq "coverage_canceled"
        expect(family.active_household.hbx_enrollments.last.aasm_state).to eq "coverage_selected"
      end

      after do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end
    end
    # rubocop:enable Lint/UselessAssignment

    describe "build_form_params" do
      let!(:tax_household10) {FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil)}
      let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000)}
      let!(:tax_household_member1) {tax_household10.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
      let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)}
      let(:applied_aptc_amount) { 120.78 }


      before :each do
        @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
        @product.update_attributes(ehb: 0.9844)
        premium_table = @product.premium_tables.first
        premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 614.85)
        premium_table.premium_tuples.where(age: 60).first.update_attributes(cost: 646.72)
        premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 679.8)
        @product.save!
        enrollment.update_attributes(product: @product, effective_on: TimeKeeper.date_of_record, applied_aptc_amount: applied_aptc_amount)
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 59, 'R-DC001').and_return(614.85)
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 60, 'R-DC001').and_return(646.72)
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 61, 'R-DC001').and_return(679.8)
        person.update_attributes!(dob: (enrollment.effective_on - 61.years))
        family.family_members[1].person.update_attributes!(dob: (enrollment.effective_on - 59.years))
      end

      it 'should return default_tax_credit_value' do
        params = subject.find(enrollment.id, family.id)
        expect(params[:default_tax_credit_value]).to eq applied_aptc_amount
      end

      it 'should return available_aptc' do
        params = subject.find(enrollment.id, family.id)
        expect(params[:available_aptc]).to eq 1274.44
      end

      it 'should return elected_aptc_pct' do
        params = subject.find(enrollment.id, family.id)
        expect(params[:elected_aptc_pct]).to eq 0.09
      end
    end

    after(:all) do
      DatabaseCleaner.clean
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end
  end
end
