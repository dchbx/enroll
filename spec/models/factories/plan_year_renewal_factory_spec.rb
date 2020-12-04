require 'rails_helper'

RSpec.describe Factories::PlanYearRenewalFactory, type: :model, dbclean: :after_each do
  context '.renew' do

    let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }
    let!(:renewal_plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'gold', active_year: effective_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", coverage_kind: 'health') }
    let!(:plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'gold', active_year: effective_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: 'health') }

    let(:generate_renewal) {
      factory = Factories::PlanYearRenewalFactory.new
      factory.employer_profile = renewing_employer
      factory.is_congress = false
      factory.renew
    }

    let!(:renewing_employees) {
      FactoryBot.create_list(:census_employee_with_active_assignment, 4, :old_case, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: renewing_employer,
        benefit_group: renewing_employer.active_plan_year.benefit_groups.first)
    }

    context 'when employer offering health benefits' do

      let(:renewing_employer) {
        FactoryBot.create(:employer_with_planyear, start_on: effective_on.prev_year,
          plan_year_state: 'active',
          reference_plan_id: plan.id)
      }

      # it 'should renew employer plan year' do
      #   generate_renewal

      #   renewing_plan_year = renewing_employer.renewing_plan_year
      #   expect(renewing_plan_year.present?).to be_truthy
      #   expect(renewing_plan_year.aasm_state).to eq 'renewing_draft'

      #   renewing_plan_year_start = renewing_employer.active_plan_year.start_on + 1.year
      #   expect(renewing_plan_year.start_on).to eq renewing_plan_year_start
      #   expect(renewing_plan_year.open_enrollment_start_on).to eq (renewing_plan_year_start - 2.months)
      #   expect(renewing_plan_year.open_enrollment_end_on).to eq (renewing_plan_year_start - 1.month + (Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on - 1).days)

      #   renewing_employer.census_employees.each do |ce|
      #     expect(ce.renewal_benefit_group_assignment.present?).to be_truthy
      #   end
      # end
    end

    context 'when Employer offering both health and dental benefits' do
      let!(:dental_renewal_plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'dental', active_year: effective_on.year, hios_id: "91111111122302", coverage_kind: 'dental', dental_level: 'high')}
      let!(:dental_plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'dental', active_year: effective_on.year - 1, hios_id: "91111111122302", renewal_plan_id: dental_renewal_plan.id, coverage_kind: 'dental', dental_level: 'high')}

      let(:renewing_employer) {
        FactoryBot.create(:employer_with_planyear, start_on: effective_on.prev_year,
          plan_year_state: 'active',
          reference_plan_id: plan.id,
          dental_reference_plan_id: dental_plan.id,
          with_dental: true
          )
      }

      it 'should generate renewal plan year with both health and dental' do
        expect(renewing_employer.renewing_plan_year.present?).to be_falsey
        generate_renewal
        expect(renewing_employer.renewing_plan_year.present?).to be_truthy
        renewed_benefit_group = renewing_employer.renewing_plan_year.benefit_groups.first
        expect(renewed_benefit_group.reference_plan).to eq renewal_plan
        expect(renewed_benefit_group.is_offering_dental?).to be_truthy
        expect(renewed_benefit_group.dental_reference_plan).to eq dental_renewal_plan
      end

      # it 'should assign renewal benefit group assignments' do
      #   renewing_employees.each{|ce| expect(ce.renewal_benefit_group_assignment.present?).to be_falsey }
      #   generate_renewal
      #   renewing_employees.each{|ce| expect(ce.renewal_benefit_group_assignment.blank?).to be_truthy }
      # end

      context 'when renewal plan year have mapping for health but not for dental' do

        let(:dental_plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'dental', active_year: effective_on.year - 1, hios_id: "91111111122302", renewal_plan_id: nil, coverage_kind: 'dental', dental_level: 'high')}

        it "should create renewal plan year with only health" do
          expect(renewing_employer.renewing_plan_year.present?).to be_falsey
          generate_renewal

          expect(renewing_employer.renewing_plan_year.present?).to be_truthy
          renewed_benefit_group = renewing_employer.renewing_plan_year.benefit_groups.first
          expect(renewed_benefit_group.reference_plan).to eq renewal_plan

          expect(renewed_benefit_group.is_offering_dental?).to be_falsey
          expect(renewed_benefit_group.dental_reference_plan).to eq nil
        end
      end

      context 'when renewal plan year have mapping for dental but not for health' do

        let!(:plan) { FactoryBot.create(:plan, market: 'shop', metal_level: 'gold', active_year: effective_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: nil, coverage_kind: 'health') }

        it "should not create renewal plan year" do
          expect(renewing_employer.renewing_plan_year.present?).to be_falsey

          active_benefit_group = renewing_employer.active_plan_year.benefit_groups.first
          expect(active_benefit_group.reference_plan.renewal_plan_id).to eq nil
          expect(active_benefit_group.dental_reference_plan.renewal_plan_id).to eq dental_renewal_plan.id

          generate_renewal
          expect(renewing_employer.renewing_plan_year.present?).to be_falsey
        end
      end

      context '.trigger_notice' do

        let(:renewal_factory) {
          Factories::PlanYearRenewalFactory.new
        }
        let(:start_on) {Date.new(2018,1,1)}
        let(:end_on) {Date.new(2018,12,31)}

        before :each do
          renewal_factory.employer_profile = renewing_employer
          renewal_factory.is_congress = false
        end

        # it "should trigger notice to employer" do
        #   expect(renewal_factory).to receive(:trigger_notice)
        #   renewal_factory.renew
        # end

        # it "should not trigger notice to employer if plan year doesn't start in 2018" do
        #   renewing_employer.plan_years.first.update_attributes!(start_on: start_on, end_on: end_on)
        #   expect(renewal_factory).not_to receive(:trigger_notice)
        #   renewal_factory.renew
        # end
      end
    end
  end
end
