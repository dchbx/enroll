# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::CalculateMonthlyAggregate do

  subject do
    described_class.new.call(hbx_enrollment: params)
  end

  describe "verify APTC calculation for full month enrollments" do
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:household) {FactoryBot.create(:household, family: family)}
    let!(:eligibility_determination_1) {FactoryBot.create(:eligibility_determination, max_aptc: sample_max_aptc_1, determined_at: start_on + 8.months, tax_household: tax_household, csr_percent_as_integer: sample_csr_percent_1)}
    let(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year,1,1), effective_ending_on: nil)}
    let(:start_on) {TimeKeeper.date_of_record.beginning_of_year}
    let(:sample_max_aptc_1) {1200.00}
    let(:sample_csr_percent_1) {87}
    let!(:hbx1) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: false,
                        effective_on: start_on,
                        terminated_on: (start_on + 4.months) - 1.day,
                        applied_aptc_amount: 300)
    end
    let!(:hbx2) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: true,
                        effective_on: start_on + 4.months,
                        terminated_on: (start_on + 8.months) - 1.day,
                        applied_aptc_amount: 200)
    end
    let!(:base_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'shopping',
                        changing: false,
                        effective_on: start_on + 8.months)
    end

    before(:each) do
      allow(family).to receive(:active_household).and_return household
    end

    describe "Not passing params to call the operation" do
      let(:params) { { } }

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "Given object is not a valid hbx enrollment object"
      end
    end

    describe "Not passing params to call the operation" do
      let(:params) { base_enrollment }

      before(:each) do
        allow(base_enrollment).to receive(:family).and_return nil
      end

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "Enrollment has no family"
      end
    end

    describe "calculated aggregate" do
      let(:params) { base_enrollment }

      it "returns monthly aggregate amount" do
        expect(subject.success).to eq 3100.0
      end
    end
  end

  describe "verify APTC calculation for enrollments starting middle of month" do
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:household) {FactoryBot.create(:household, family: family)}
    let!(:eligibility_determination_1) {FactoryBot.create(:eligibility_determination, max_aptc: sample_max_aptc_1, determined_at: start_on + 8.months, tax_household: tax_household, csr_percent_as_integer: sample_csr_percent_1)}
    let(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year,1,1), effective_ending_on: nil)}
    let(:start_on) {TimeKeeper.date_of_record.beginning_of_year}
    let(:sample_max_aptc_1) {1200.00}
    let(:sample_csr_percent_1) {87}
    let!(:hbx1) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: false,
                        effective_on: start_on,
                        terminated_on: start_on.end_of_month - 1.day,
                        applied_aptc_amount: 300)
    end
    let!(:hbx2) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: true,
                        effective_on: start_on + 1.month + 14.days,
                        terminated_on: (start_on + 4.month) + 17.days,
                        applied_aptc_amount: 200)
    end
    let!(:base_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'shopping',
                        changing: false,
                        effective_on: start_on + 10.months)
    end

    before(:each) do
      allow(family).to receive(:active_household).and_return household
    end

    describe "calculated aggregate" do
      let(:params) { base_enrollment }

      it "returns monthly aggregate amount" do
        expect(subject.success).to eq 6745.05
      end
    end
  end

  describe "verify APTC calculation for enrollments terminated middle of month" do
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:household) {FactoryBot.create(:household, family: family)}
    let!(:eligibility_determination_1) {FactoryBot.create(:eligibility_determination, max_aptc: sample_max_aptc_1, determined_at: start_on + 8.months, tax_household: tax_household, csr_percent_as_integer: sample_csr_percent_1)}
    let(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year,1,1), effective_ending_on: nil)}
    let(:start_on) {TimeKeeper.date_of_record.beginning_of_year}
    let(:sample_max_aptc_1) {1200.00}
    let(:sample_csr_percent_1) {87}
    let!(:hbx1) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: false,
                        effective_on: start_on + 4.days,
                        terminated_on: start_on.end_of_month - 1.day,
                        applied_aptc_amount: 300)
    end
    let!(:hbx2) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: true,
                        effective_on: (start_on + 1.months).end_of_month,
                        terminated_on: (start_on + 4.months).end_of_month,
                        applied_aptc_amount: 200)
    end
    let!(:base_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'shopping',
                        changing: false,
                        effective_on: (start_on + 10.months) + 9.days)
    end

    before(:each) do
      allow(family).to receive(:active_household).and_return household
    end

    describe "calculated aggregate" do
      let(:params) { base_enrollment }

      it "returns monthly aggregate amount" do
        expect(subject.success).to eq 7959.89
      end
    end
  end

  describe "verify APTC amount for multiple enrollments" do
    let(:start_on) {TimeKeeper.date_of_record.beginning_of_year}
    let(:household) {FactoryBot.create(:household, family: family)}
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:family_member1) {FactoryBot.create(:family_member, family: household.family)}
    let(:family_member2) {FactoryBot.create(:family_member, family: household.family)}
    let!(:eligibility_determination_1) {FactoryBot.create(:eligibility_determination, max_aptc: sample_max_aptc_1, determined_at: start_on + 8.months, tax_household: tax_household, csr_percent_as_integer: sample_csr_percent_1)}
    let(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: start_on, effective_ending_on: nil)}
    let(:sample_max_aptc_1) {1200.00}
    let(:sample_csr_percent_1) {87}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx3, applicant_id: family_member1.id, eligibility_date: TimeKeeper.date_of_record.beginning_of_month)}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: base_enrollment, applicant_id: family_member2.id, eligibility_date: TimeKeeper.date_of_record.beginning_of_month)}
    let!(:hbx1) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: false,
                        effective_on: start_on,
                        terminated_on: (start_on + 2.months).end_of_month - 6.day,
                        applied_aptc_amount: 300)
    end
    let!(:hbx2) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: true,
                        effective_on: (start_on + 2.months).end_of_month - 6.day,
                        terminated_on: (start_on + 4.month) + 4.day,
                        applied_aptc_amount: 200)
    end
    let!(:hbx3) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_enrolled',
                        changing: true,
                        effective_on: (start_on + 4.month) + 15.day,
                        applied_aptc_amount: 200)
    end

    let!(:base_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'shopping',
                        changing: false,
                        effective_on: start_on + 5.months)
    end

    before(:each) do
      allow(family).to receive(:active_household).and_return household
    end

    describe "calculated aggregate" do
      let(:params) { base_enrollment }

      it "returns monthly aggregate amount" do
        expect(subject.success).to eq 1682.48
      end
    end
  end

  describe "verify APTC amount for multiple enrollments with gap b/w enrollments" do
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:household) {FactoryBot.create(:household, family: family)}
    let!(:eligibility_determination_1) {FactoryBot.create(:eligibility_determination, max_aptc: sample_max_aptc_1, determined_at: start_on + 8.months, tax_household: tax_household, csr_percent_as_integer: sample_csr_percent_1)}
    let(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year,1,1), effective_ending_on: nil)}
    let(:start_on) {TimeKeeper.date_of_record.beginning_of_year}
    let(:sample_max_aptc_1) {1200.00}
    let(:sample_csr_percent_1) {87}
    let!(:hbx1) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: false,
                        effective_on: start_on,
                        terminated_on: (start_on + 1.months) + 14.days,
                        applied_aptc_amount: 300)
    end
    let!(:hbx2) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: true,
                        effective_on: (start_on + 2.months) + 14.days,
                        terminated_on: (start_on + 4.month) + 1.day,
                        applied_aptc_amount: 200)
    end
    let!(:hbx3) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: true,
                        effective_on: (start_on + 5.month) + 4.day,
                        terminated_on: (start_on + 6.month) + 14.day,
                        applied_aptc_amount: 200)
    end

    let!(:base_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'shopping',
                        changing: false,
                        effective_on: start_on + 10.months)
    end

    before(:each) do
      allow(family).to receive(:active_household).and_return household
    end

    describe "calculated aggregate" do
      let(:params) { base_enrollment }

      it "returns monthly aggregate amount" do
        expect(subject.success).to eq 6676.06
      end
    end
  end

  describe "verify APTC amount for prior year" do
    let(:start_on) {TimeKeeper.date_of_record.beginning_of_year - 1.year}
    let(:current_year) {TimeKeeper.date_of_record.beginning_of_year}
    let(:household) {FactoryBot.create(:household, family: family)}
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:family_member1) {FactoryBot.create(:family_member, family: household.family)}
    let(:family_member2) {FactoryBot.create(:family_member, family: household.family)}
    let!(:eligibility_determination_1) {FactoryBot.create(:eligibility_determination, max_aptc: sample_max_aptc_1, determined_at: start_on + 8.months, tax_household: tax_household, csr_percent_as_integer: sample_csr_percent_1)}
    let(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: start_on, effective_ending_on: nil)}
    let(:sample_max_aptc_1) {1200.00}
    let(:sample_csr_percent_1) {87}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: hbx3, applicant_id: family_member1.id, eligibility_date: start_on)}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: base_enrollment, applicant_id: family_member2.id, eligibility_date: start_on)}

    let!(:hbx1) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: false,
                        effective_on: start_on,
                        terminated_on: (start_on + 2.months).end_of_month - 6.day,
                        applied_aptc_amount: 300)
    end
    let!(:hbx2) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_terminated',
                        changing: true,
                        effective_on: (start_on + 2.months).end_of_month - 6.day,
                        terminated_on: (start_on + 4.month) + 4.day,
                        applied_aptc_amount: 200)
    end
    let!(:hbx3) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_enrolled',
                        changing: true,
                        effective_on: (start_on + 4.month) + 15.day,
                        applied_aptc_amount: 200)
    end
    # this enrollment should not be considered by yearly aggregate calculations
    let!(:hbx4) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_enrolled',
                        changing: true,
                        effective_on: (TimeKeeper.date_of_record.beginning_of_year + 1.month) + 15.day,
                        applied_aptc_amount: 300)
    end

    let!(:base_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'shopping',
                        changing: false,
                        effective_on: start_on + 11.months)
    end

    before(:each) do
      allow(family).to receive(:active_household).and_return household
    end

    describe "calculated aggregate" do
      let(:params) { base_enrollment }

      it "returns yearly aggregate amount" do
        expect(subject.success).to eq 11_777.41
      end
    end
  end
end
