# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'update_enrollment_with_aptc')

describe UpdateEnrollmentWithAptc, dbclean: :after_each do

  let(:given_task_name)            { 'update_enrollment_with_aptc' }
  let(:subject)                    { UpdateEnrollmentWithAptc.new(given_task_name, double(:current_scope => nil)) }
  let!(:person)                    { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let!(:family)                    { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
  let!(:sbc_document)              { FactoryBot.build(:document, subject: 'SBC', identifier: 'urn:openhbx#123')}
  let(:today)                      { TimeKeeper.date_of_record }
  let!(:product)                   { FactoryBot.create(:benefit_markets_products_health_products_health_product, title: 'AAA', issuer_profile_id: 'ab1233', benefit_market_kind: :aca_individual, sbc_document: sbc_document)}
  let!(:hbx_enrollment)            { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, consumer_role_id: person.consumer_role.id)}
  let!(:hbx_enrollment_member1)    { FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, eligibility_date: today, hbx_enrollment: hbx_enrollment, coverage_start_on: today)}
  let!(:hbx_enrollment_member2)    { FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, eligibility_date: today, coverage_start_on: today, hbx_enrollment: hbx_enrollment)}
  let!(:hbx_profile)               { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
  let!(:tax_household)             { FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil)}
  let!(:eligibility_determination) { FactoryBot.create(:eligibility_determination, tax_household: tax_household, max_aptc: 2000)}
  let!(:tax_household_member1)     { tax_household.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
  let!(:tax_household_member2)     { tax_household.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)}
  let(:new_effective_on)           { (today - 1.month).beginning_of_month }

  let!(:params) do
    {
      enrollment_hbx_id: hbx_enrollment.hbx_id, applied_aptc_amount: '904', new_effective_date: new_effective_on.to_s
    }
  end

  before :each do
    @product = BenefitMarkets::Products::Product.all.where(benefit_market_kind: :aca_individual).first
    @product.update_attributes(ehb: 0.9844)
    premium_table = @product.premium_tables.first
    premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 614.85)
    premium_table.premium_tuples.where(age: 60).first.update_attributes(cost: 646.72)
    premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 679.8)
    @product.save!
    hbx_enrollment.update_attributes(product: @product, effective_on: today)
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, new_effective_on, 59, 'R-DC001').and_return(614.85)
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, new_effective_on, 60, 'R-DC001').and_return(646.72)
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(@product, new_effective_on, 61, 'R-DC001').and_return(679.8)
    person.update_attributes!(dob: (new_effective_on - 61.years))
    family.family_members[1].person.update_attributes!(dob: (new_effective_on - 59.years))
  end

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'updating enrollment with aptc' do
    it 'should change effective on date' do
      ClimateControl.modify params do
        expect(hbx_enrollment.applied_aptc_amount).to eq 0
        subject.migrate
        new_enrollment = HbxEnrollment.all.max_by(&:created_at)
        expect(new_enrollment.applied_aptc_amount.to_f).to eq 904.00
        expect(new_enrollment.effective_on).to eq new_effective_on
        expect(new_enrollment.aasm_state).to eq 'unverified'
      end
    end
  end

  describe 'updating enrollment with aptc and terminating' do
    let(:terminated_on)             { new_effective_on.end_of_month }
    let(:params_with_terminated_on) { params.merge({ terminated_on: terminated_on.to_s})}

    it 'should change applied aptc and terminated on date' do
      ClimateControl.modify params_with_terminated_on do
        expect(hbx_enrollment.applied_aptc_amount).to eq 0
        expect(hbx_enrollment.terminated_on).to eq nil
        subject.migrate
        new_enrollment = HbxEnrollment.all.max_by(&:created_at)
        expect(new_enrollment.applied_aptc_amount.to_f).to eq 904.00
        expect(new_enrollment.effective_on).to eq new_effective_on
        expect(new_enrollment.terminated_on).to eq terminated_on
        expect(new_enrollment.aasm_state).to eq 'coverage_terminated'
      end
    end
  end
end
