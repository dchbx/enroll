# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/spec/shared_contexts/enrollment.rb"

RSpec.describe Services::IvlEnrollmentRenewalService, type: :model, :dbclean => :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  context "Assisted enrollment" do
    include_context "setup families enrollments"

    let!(:renewal_enrollment_assisted) do
      FactoryBot.create(:hbx_enrollment, :individual_assisted, :with_enrollment_members,
                        consumer_role_id: family_assisted.primary_family_member.person.consumer_role.id,
                        effective_on: renewal_calender_date,
                        household: family_assisted.active_household,
                        family: family_assisted,
                        enrollment_members: [family_assisted.family_members.first],
                        product: renewal_csr_87_product)
    end

    subject do
      Services::IvlEnrollmentRenewalService.new(renewal_enrollment_assisted)
    end

    let(:aptc_values) do
      { applied_percentage: 87,
        applied_aptc: 150,
        csr_amt: 87,
        max_aptc: 200 }
    end

    let(:bad_aptc_values) do
      { applied_percentage: '',
        csr_amt: 87,
        max_aptc: 200 }
    end

    before do
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
        slcsp_id = if bcp.start_on.year == renewal_csr_87_product.application_period.min.year
                     renewal_csr_87_product.id
                   else
                     active_csr_87_product.id
                   end
        bcp.update_attributes!(slcsp_id: slcsp_id)
      end
      hbx_profile.reload

      family_assisted.active_household.reload
      family_assisted.primary_family_member.person.update_attributes(dob: (Time.zone.today - 45.years))
      family_assisted.reload
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
    end

    context 'invalid arguments' do
      it 'should raise error as enrollment is not valid' do
        expect{Services::IvlEnrollmentRenewalService.new(nil)}.to raise_error(RuntimeError, 'Hbx Enrollment Missing!!!')
      end

      it 'should raise error if any of the arguments are not valid' do
        expect{subject.assign(bad_aptc_values)}.to raise_error(RuntimeError, 'Provide aptc values {applied_aptc: , applied_percentage: , max_aptc:}')
      end
    end

    context 'for applied_aptc_amount' do
      it "should return ehb_premium" do
        renewel_enrollment = subject.assign(aptc_values)
        expect(renewel_enrollment.applied_aptc_amount.to_f).to eq((renewel_enrollment.total_premium * renewel_enrollment.product.ehb).round(2))
      end

      it "should return selected aptc" do
        aptc_values[:applied_aptc] = 20.00
        renewel_enrollment = subject.assign(aptc_values)
        expect(renewel_enrollment.applied_aptc_amount.to_f).to eq(aptc_values[:applied_aptc])
      end

      it "should return available_aptc" do
        eligibility_determination1.update_attributes!(max_aptc: 15.00)
        renewel_enrollment = subject.assign(aptc_values)
        expect(renewel_enrollment.applied_aptc_amount.to_f).to eq(eligibility_determination1.max_aptc.to_f)
      end
    end

    it "should get min on given applied, ehb premium and available aptc" do
      expect(subject.send(:calculate_applicable_aptc, aptc_values).nil?).to eq false
    end
  end
end
