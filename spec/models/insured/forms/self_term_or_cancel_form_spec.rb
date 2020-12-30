# frozen_string_literal: true

require 'rails_helper'

module Insured
  RSpec.describe Forms::SelfTermOrCancelForm, type: :model, dbclean: :after_each do

    before do
      DatabaseCleaner.clean
    end

    subject { Insured::Forms::SelfTermOrCancelForm.new }

    describe "model attributes" do
      it {
        [:carrier_logo, :enrollment, :family, :is_aptc_eligible, :market_kind, :product, :term_date].each do |key|
          expect(subject.attributes.key?(key)).to be_truthy
        end
      }
    end

    describe "validate Form" do

      let(:valid_params) do
        {
          :market_kind => "kind"
        }
      end

      let(:invalid_params) do
        {
          :market_kind => nil
        }
      end

      context "with invalid params" do

        let(:build_self_term_or_cancel_form) { Insured::Forms::SelfTermOrCancelForm.new(invalid_params)}

        it "should return false" do
          expect(build_self_term_or_cancel_form.valid?).to be_falsey
        end
      end

      context "with valid params" do

        let(:build_self_term_or_cancel_form) { Insured::Forms::SelfTermOrCancelForm.new(valid_params)}

        it "should return true" do
          expect(build_self_term_or_cancel_form.valid?).to be_truthy
        end
      end
    end

    describe "#for_view" do
      let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
      let!(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
      let(:sep) {FactoryBot.create(:special_enrollment_period, family: family)}
      let!(:enrollment) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: @product, consumer_role_id: person.consumer_role.id)}
      let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: enrollment)}
      let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: enrollment)}
      let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
      let!(:tax_household10) {FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil)}
      let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000)}
      let!(:tax_household_member1) {tax_household10.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
      let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)}
      let(:applied_aptc_amount) { 120.78 }

      before(:each) do
        @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
        @product.update_attributes(ehb: 0.9844)
        premium_table = @product.premium_tables.first
        premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 614.85)
        premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 679.8)
        @product.save!
        enrollment.update_attributes(product: @product, applied_aptc_amount: applied_aptc_amount)
        hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 59, 'R-DC001').and_return(814.85)
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, enrollment.effective_on, 61, 'R-DC001').and_return(879.8)
        person.update_attributes!(dob: (enrollment.effective_on - 61.years))
        family.family_members[1].person.update_attributes!(dob: (enrollment.effective_on - 59.years))
      end

      it 'should create a valid form for the view' do
        family.special_enrollment_periods << sep
        attrs = {enrollment_id: enrollment.id.to_s, family_id: family.id}
        form = Insured::Forms::SelfTermOrCancelForm.for_view(attrs)
        expect(Insured::Forms::SelfTermOrCancelForm.self_term_or_cancel_service(attrs)).to be_instance_of(Insured::Services::SelfTermOrCancelService)
        expect(form.enrollment).not_to be nil
        expect(form.family).not_to be nil
        expect(form.product).not_to be nil
      end

      it 'should return available_aptc' do
        family.special_enrollment_periods << sep
        attrs = {enrollment_id: enrollment.id.to_s, family_id: family.id}
        form = Insured::Forms::SelfTermOrCancelForm.for_view(attrs)
        expect(form.available_aptc).to eq 1668.2
      end

      it 'should return default_tax_credit_value' do
        family.special_enrollment_periods << sep
        attrs = {enrollment_id: enrollment.id.to_s, family_id: family.id}
        form = Insured::Forms::SelfTermOrCancelForm.for_view(attrs)
        expect(form.default_tax_credit_value).to eq applied_aptc_amount
      end

      it 'should return new_enrollment_premium' do
        family.special_enrollment_periods << sep
        attrs = {enrollment_id: enrollment.id.to_s, family_id: family.id}
        form = Insured::Forms::SelfTermOrCancelForm.for_view(attrs)
        expect(form.new_enrollment_premium).to eq 1573.87
      end
    end

    describe "#for_post" do
      let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
      let(:sep) {FactoryBot.create(:special_enrollment_period, family: family) }
      let(:sbc_document) { FactoryBot.build(:document, subject: "SBC", identifier: "urn:openhbx#124") }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, title: "AAA", issuer_profile_id: "ab1233", sbc_document: sbc_document) }
      let(:enrollment_to_cancel) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today + 1.month) }
      let(:enrollment_to_term) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today - 1.month) }

      it "should cancel an enrollment if it is not yet effective" do
        attrs = {enrollment_id: enrollment_to_cancel.id, term_date: TimeKeeper.date_of_record.to_s}
        Insured::Forms::SelfTermOrCancelForm.for_post(attrs)
        enrollment_to_cancel.reload
        expect(enrollment_to_cancel.aasm_state).to eq 'coverage_canceled'
      end

      it "should terminate an enrollment if it is already effective" do
        attrs = {enrollment_id: enrollment_to_term.id, term_date: (TimeKeeper.date_of_record + 1.month).to_s}
        Insured::Forms::SelfTermOrCancelForm.for_post(attrs)
        enrollment_to_term.reload
        expect(enrollment_to_term.aasm_state).to eq 'coverage_terminated'
      end
    end

  end
end
