# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::CalculateMonthlyAggregate do

  before do
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, 8, 1))
  end

  context 'for invalid params' do
    it 'should return a failure with a message' do
      expect(subject.call({family: 'family'}).failure).to eq('Given object is not a valid family object.')
    end
  end

  let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:primary_fm) {family.primary_applicant}
  let!(:household) {family.active_household}
  let!(:current_date){TimeKeeper.date_of_record}
  let!(:year_start_date) {TimeKeeper.date_of_record.beginning_of_year}

  context 'for current year effective dates' do
    let!(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: year_start_date, effective_ending_on: nil)}
    let!(:ed) {FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: tax_household)}
    let(:hbx_enrollment) do
      enr = FactoryBot.create(:hbx_enrollment,
                              family: family,
                              household: household,
                              is_active: true,
                              aasm_state: 'coverage_terminated',
                              changing: false,
                              effective_on: year_start_date,
                              terminated_on: terminated_on,
                              applied_aptc_amount: 300.00)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end

    context 'for full month enrollments' do
      let(:effective_on) {current_date}
      let(:terminated_on) {effective_on.prev_day}
      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(780.00)
      end
    end

    context 'for effective date starting middle of month and existing enrrollment terminated in middle of the month' do
      let(:effective_on) {current_date + 14.days}
      let(:terminated_on) {effective_on.prev_day}
      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(827.65)
      end
    end

    context 'for effective date starting middle of month and existing enrrollment terminated at the end of prev month' do
      let(:effective_on) {current_date + 14.days}
      let(:terminated_on) {current_date.prev_day}
      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(857.44)
      end
    end

    context 'for effective date starting stat of month and existing enrrollment terminated in middle of the month' do
      let(:effective_on) {current_date}
      let(:terminated_on) {current_date - 12.days}
      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(801.29)
      end
    end

    context 'for multiple enrollments with different subscribers' do
      let(:effective_on) {current_date}
      let(:terminated_on) {current_date.prev_day}
      let!(:fm2) do
        per2 = FactoryBot.create(:person, :with_consumer_role)
        person.ensure_relationship_with(per2, 'spouse')
        FactoryBot.create(:family_member, family: family, person: per2)
      end
      let!(:hbx_enrollment2) do
        enr2 = FactoryBot.create(:hbx_enrollment,
                                 family: family,
                                 household: household,
                                 is_active: true,
                                 aasm_state: 'coverage_selected',
                                 changing: false,
                                 effective_on: year_start_date,
                                 terminated_on: nil,
                                 applied_aptc_amount: 100.00)
        FactoryBot.create(:hbx_enrollment_member, applicant_id: fm2.id, hbx_enrollment: enr2)
        enr2
      end

      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(540.00)
      end
    end

    context 'for multiple enrollments with same subscriber' do
      let(:effective_on) {current_date}
      let(:terminated_on) {current_date.prev_month.prev_month.prev_day}
      let!(:hbx_enrollment2) do
        enr2 = FactoryBot.create(:hbx_enrollment,
                                 family: family,
                                 household: household,
                                 is_active: true,
                                 aasm_state: 'coverage_selected',
                                 changing: false,
                                 effective_on: terminated_on.next_day,
                                 terminated_on: nil,
                                 applied_aptc_amount: 100.00)
        FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr2)
        enr2
      end

      before do
        input_params = {family: family, effective_on: effective_on, shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
        @result = subject.call(input_params)
      end

      it 'should return monthly aggregate amount' do
        expect(@result.success).to eq(860.00)
      end
    end
  end

  context 'for prior year effective_on' do
    let(:prev_year_start_date) {year_start_date.prev_year}
    let!(:old_tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: prev_year_start_date, effective_ending_on: nil)}
    let!(:old_ed) {FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: old_tax_household)}
    let(:hbx_enrollment) do
      enr = FactoryBot.create(:hbx_enrollment,
                              family: family,
                              household: household,
                              is_active: true,
                              aasm_state: 'coverage_expired',
                              changing: false,
                              effective_on: prev_year_start_date,
                              terminated_on: nil,
                              applied_aptc_amount: 300.00)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end

    before do
      input_params = {family: family, effective_on: Date.new(prev_year_start_date.year, 11, 1), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
      @result = subject.call(input_params)
    end

    it 'should return monthly aggregate amount' do
      expect(@result.success).to eq(1500.00)
    end
  end

  context 'for termination on set to end of year' do
    let(:prev_year_start_date) {year_start_date.prev_year}
    let!(:old_tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: prev_year_start_date, effective_ending_on: nil)}
    let!(:old_ed) {FactoryBot.create(:eligibility_determination, max_aptc: 500.00, tax_household: old_tax_household)}
    let(:hbx_enrollment) do
      enr = FactoryBot.create(:hbx_enrollment,
                              family: family,
                              household: household,
                              is_active: true,
                              aasm_state: 'coverage_expired',
                              changing: false,
                              effective_on: prev_year_start_date,
                              terminated_on: nil,
                              applied_aptc_amount: 300.00)
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end
    before do
      EnrollRegistry[:calculate_monthly_aggregate].feature.settings.first.stub(:item).and_return("end_of_year")
      input_params = {family: family, effective_on: Date.new(prev_year_start_date.year, 11, 1), shopping_fm_ids: hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id), subscriber_applicant_id: hbx_enrollment.subscriber.applicant_id}
      @result = subject.call(input_params)
    end

    it 'should return monthly aggregate amount' do
      expect(@result.success).to eq(1200.00)
    end
  end
end
