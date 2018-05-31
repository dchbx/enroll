require 'rails_helper'
require File.join(Rails.root, "script", "shop_sep_query")

describe '.can_publish_enrollment?', :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.months }
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: start_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: 'health') }
  let(:renewal_plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", coverage_kind: 'health') }

  context 'initial employer' do
    let(:employer) { FactoryGirl.create(:employer_with_planyear, start_on: start_on, plan_year_state: plan_year_status, reference_plan_id: plan.id, aasm_state: employer_status) }
    let(:plan_year) { employer.plan_years.first }
    let(:enrollment) { instance_double(HbxEnrollment, benefit_group: plan_year.benefit_groups[0], aasm_state: 'coverage_selected', effective_on: enrollment_effective_on) }
    let(:submitted_at) { plan_year.enrollment_quiet_period.max + 5.hours }
    let(:employer_status) { 'binder_paid' }
    let(:enrollment_effective_on) { start_on }

    before do
      allow(enrollment).to receive(:employer_profile).and_return(employer)
    end

    context 'when plan year is invalid' do 
      let(:plan_year_status) { 'enrolling' }

      context 'enrollment submitted after quiet period' do
        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_falsey
        end
      end
    end

    context 'when plan year is valid' do 
      let(:plan_year_status) { 'enrolled' }

      before do 
        allow(enrollment).to receive(:new_hire_enrollment_for_shop?).and_return(false)
      end

      context 'enrollment submitted after quiet period' do 
        it 'should publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_truthy
        end
      end

      context 'enrollment submitted with in quiet period' do
        let(:submitted_at) { plan_year.enrollment_quiet_period.max - 3.hours }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_falsey
        end
      end

      context 'enrollment submitted during open enrollment' do
        let(:submitted_at) { plan_year.open_enrollment_end_on.prev_day }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_falsey
        end
      end
    end

    context 'when enrollment is new hire enrollment' do 
      let(:plan_year_status) { 'enrolled' }

      before do 
        allow(enrollment).to receive(:new_hire_enrollment_for_shop?).and_return(true)
      end

      context 'enrollment effective date with in 2 months in the past' do
        let(:enrollment_effective_on) { TimeKeeper.date_of_record - 5.days }

        it 'should publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_truthy
        end
      end

      context 'enrollment effective date is more than 2 months in the past' do
        let(:enrollment_effective_on) { TimeKeeper.date_of_record - 3.months }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_falsey
        end
      end
    end
  end

  context 'renewing employer' do
    let(:employer) {
      FactoryGirl.create(:employer_with_renewing_planyear, start_on: start_on,
        renewal_plan_year_state: plan_year_status,
        reference_plan_id: plan.id,
        renewal_reference_plan_id: renewal_plan.id,
        )
    }

    let(:plan_year) { employer.renewing_plan_year }
    let(:enrollment) { instance_double(HbxEnrollment, benefit_group: plan_year.benefit_groups[0], aasm_state: enrollment_status, effective_on: enrollment_effective_on) }
    let(:submitted_at) { plan_year.enrollment_quiet_period.max + 5.hours }
    let(:employer_status) { 'enrolled' }
    let(:enrollment_status) { 'coverage_selected' }
    let(:enrollment_effective_on) { start_on }

    before do
      allow(enrollment).to receive(:employer_profile).and_return(employer)
    end

    context 'when plan year is invalid' do 
      let(:plan_year_status) { 'renewing_enrolling' }

      context 'enrollment submitted after quiet period' do
        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_falsey
        end
      end
    end

    context 'when plan year is valid' do 
      let(:plan_year_status) { 'renewing_enrolled' }
      let(:enrollment_status) { 'auto_renewing' }

      before do
        allow(enrollment).to receive(:new_hire_enrollment_for_shop?).and_return(false)
      end

      context 'enrollment submitted after quiet period' do 
        it 'should publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_truthy
        end
      end

      context 'enrollment submitted with in quiet period' do
        let(:submitted_at) { plan_year.enrollment_quiet_period.max - 3.hours }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_falsey
        end
      end

      context 'enrollment submitted during open enrollment' do
        let(:submitted_at) { plan_year.open_enrollment_end_on.prev_day }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_falsey
        end
      end
    end

    context 'when enrollment is new hire enrollment' do 
      let(:plan_year_status) { 'renewing_enrolled' }

      before do 
        allow(enrollment).to receive(:new_hire_enrollment_for_shop?).and_return(true)
      end

      context 'enrollment effective date with in 2 months in the past' do
        let(:enrollment_effective_on) { TimeKeeper.date_of_record - 5.days }

        it 'should publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_truthy
        end
      end

      context 'enrollment effective date is more than 2 months in the past' do
        let(:enrollment_effective_on) { TimeKeeper.date_of_record - 3.months }

        it 'should not publish enrollment' do
          expect(can_publish_enrollment?(enrollment, submitted_at)).to be_falsey
        end
      end
    end
  end
end
