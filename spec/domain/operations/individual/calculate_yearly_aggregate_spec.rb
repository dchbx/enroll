# frozen_string_literal: true

require 'rails_helper'
module Operations
  module Individual
    RSpec.describe CalculateYearlyAggregate do
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
                          aasm_state: 'shopping',
                          changing: false,
                          effective_on: start_on + 8.months)
      end
      let!(:hbx2) do
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
      let!(:hbx3) do
        FactoryBot.create(:hbx_enrollment,
                          family: family,
                          household: household,
                          is_active: true,
                          aasm_state: 'coverage_enrolled',
                          changing: true,
                          effective_on: start_on + 4.months,
                          applied_aptc_amount: 200)
      end

      before(:each) do
        allow(family).to receive(:active_household).and_return household
      end

      subject do
        described_class.new.call(hbx_enrollment: params)
      end

      describe "Not passing params to call the operation" do
        let(:params) { { } }

        it "fails" do
          expect(subject).not_to be_success
          expect(subject.failure).to eq "Given object is not a valid hbx enrollment object"
        end
      end

      describe "Not passing params to call the operation" do
        let(:params) { hbx1 }

        before(:each) do
          allow(hbx1).to receive(:family).and_return nil
        end

        it "fails" do
          expect(subject).not_to be_success
          expect(subject.failure).to eq "Enrollment has no family"
        end
      end

      describe "calculated aggregate" do
        let(:params) { hbx1 }

        it "returns yearly aggregate amount" do
          expect(subject.success).to eq 3100.0
        end
      end
    end
  end
end

