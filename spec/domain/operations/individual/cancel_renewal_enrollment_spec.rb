# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, 'spec/shared_contexts/dchbx_product_selection')

RSpec.describe Operations::Individual::CancelRenewalEnrollment, dbclean: :after_each do
  let(:current_year) { TimeKeeper.date_of_record.year }

  subject do
    described_class.new.call(hbx_enrollment: params)
  end

  describe "Not passing params to call the operation" do
    let(:params) { { } }

    it "fails" do
      expect(subject).not_to be_success
      expect(subject.failure).to eq "Given object is not a valid enrollment object"
    end
  end

  describe "Should cancel renewal enrollment when terminating present enrollment under OR period " do

    include_context 'family with previous enrollment for termination and passive renewal'
    let(:params) { expired_enrollment }

    before do
      family.hbx_enrollments.where(effective_on: TimeKeeper.date_of_record.next_year.beginning_of_year).first.update_attributes(aasm_state: "auto_renewing")
      expired_enrollment.update_attributes(aasm_state: :coverage_selected)
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
    end

    it 'should cancel renewal enrollment when passed an active enrollment' do
      renewal_enrollment = family.hbx_enrollments.where(effective_on: TimeKeeper.date_of_record.next_year.beginning_of_year).first
      expect(renewal_enrollment.aasm_state).to eq "auto_renewing"
      expect(subject).to be_success
      renewal_enrollment.reload
      expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
    end
  end

  describe "Should not cancel second renewal enrollment when terminating renewal enrollment under OR period " do
    before do
      expired_enrollment.update_attributes(aasm_state: :coverage_selected)
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
    end

    include_context 'family with previous enrollment for termination and second passive renewal'
    let(:params) { renewal_enrollment }

    it 'should cancel renewal enrollment when passed an active enrollment' do
      expect(renewal_enrollment.aasm_state).to eq "coverage_selected"
      expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
      expect(subject).to be_success
      renewal_enrollment2.reload
      renewal_enrollment.reload
      expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
    end
  end

  describe "Should not cancel second renewal enrollment when terminating present enrollment under OR period " do
    before do
      renewal_enrollment.update_attributes(aasm_state: "auto_renewing")
      expired_enrollment.update_attributes(aasm_state: :coverage_selected)
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
    end

    include_context 'family with previous enrollment for termination and second passive renewal'
    let(:params) { expired_enrollment }

    it 'should cancel renewal enrollment when passed an active enrollment' do
      expect(renewal_enrollment.aasm_state).to eq "auto_renewing"
      expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
      expect(subject).to be_success
      renewal_enrollment2.reload
      renewal_enrollment.reload
      expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
      expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
    end
  end

  describe "Should cancel passive renewal enrollment when terminating present enrollment under OR period with effective on not same as renewal previous year" do
    include_context 'family with previous enrollment not beginning of year for termination and second passive renewal'
    let(:params) { expired_enrollment }

    context "should cancel passive renewal" do
      before do
        renewal_enrollment.update_attributes(aasm_state: "auto_renewing")
        expired_enrollment.update_attributes(aasm_state: :coverage_selected)
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
      end

      it 'should cancel renewal enrollment when passed an active enrollment' do
        expect(renewal_enrollment.aasm_state).to eq "auto_renewing"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
        expect(subject).to be_success
        renewal_enrollment2.reload
        renewal_enrollment.reload
        expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
      end
    end

    context "should cancel active renewed coverage same as passive renewal" do
      before do
        renewal_enrollment.update_attributes(aasm_state: "renewing_coverage_selected")
        expired_enrollment.update_attributes(aasm_state: :coverage_selected)
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
      end

      it 'should cancel active renewed enrollment on terminating active coverage' do
        expect(renewal_enrollment.aasm_state).to eq "renewing_coverage_selected"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
        expect(subject).to be_success
        renewal_enrollment2.reload
        renewal_enrollment.reload
        expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
      end
    end

    context "should not cancel active renewed coverage with different carrier on terminating active coverage" do

      let!(:gold_renewal_product) do
        FactoryBot.create(:benefit_markets_products_health_products_health_product,
                          :ivl_product,
                          :gold,
                          renewal_product_id: renewal_product.id,
                          issuer_profile_id: '1',
                          application_period: start_of_year..end_of_year)
      end
      before do
        product.update_attributes(issuer_profile_id: '2')
        renewal_enrollment.update_attributes(product_id: gold_renewal_product.id, aasm_state: "renewing_coverage_selected")
        expired_enrollment.update_attributes(aasm_state: :coverage_selected)
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
      end

      it 'should not cancel active renewed enrollment' do
        expect(renewal_enrollment.aasm_state).to eq "renewing_coverage_selected"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
        expect(subject).to be_success
        renewal_enrollment2.reload
        renewal_enrollment.reload
        expect(renewal_enrollment.aasm_state).to eq "renewing_coverage_selected"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
      end
    end

    context "should cancel active renewed coverage on terminating active coverage when renewal base id matchs with active coverage" do

      let!(:gold_renewal_product) do
        FactoryBot.create(:benefit_markets_products_health_products_health_product,
                          :ivl_product,
                          :gold,
                          hios_base_id: '41842DC040001',
                          application_period: start_of_year..end_of_year)
      end
      before do
        product.update_attributes(hios_base_id: '41842DC040001')
        renewal_enrollment.update_attributes(product_id: gold_renewal_product.id, aasm_state: "renewing_coverage_selected")
        expired_enrollment.update_attributes(aasm_state: :coverage_selected)
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
      end

      it 'should cancel active renewed enrollment' do
        expect(renewal_enrollment.aasm_state).to eq "renewing_coverage_selected"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
        expect(subject).to be_success
        renewal_enrollment2.reload
        renewal_enrollment.reload
        expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
      end
    end

    context "should cancel active renewed coverage on terminating active coverage when issuer profile matchs with active coverage" do
      let!(:gold_renewal_product) do
        FactoryBot.create(:benefit_markets_products_health_products_health_product,
                          :ivl_product,
                          :gold,
                          issuer_profile_id: '1',
                          application_period: start_of_year..end_of_year)
      end
      before do
        product.update_attributes(issuer_profile_id: '1')
        renewal_enrollment.update_attributes(product_id: gold_renewal_product.id, aasm_state: "renewing_coverage_selected")
        expired_enrollment.update_attributes(aasm_state: :coverage_selected)
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
      end

      it 'should cancel active renewed enrollment' do
        expect(renewal_enrollment.aasm_state).to eq "renewing_coverage_selected"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
        expect(subject).to be_success
        renewal_enrollment2.reload
        renewal_enrollment.reload
        expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
      end
    end

    context "should not cancel member added active renewed enrollment on terminating active coverage" do
      let!(:new_person) { FactoryBot.create(:person, :with_consumer_role)}
      let!(:new_fam_member) { FactoryBot.create(:family_member, family: family, person: new_person) }
      let!(:new_member) do
        FactoryBot.create(:hbx_enrollment_member,
                          hbx_enrollment: renewal_enrollment,
                          applicant_id: new_fam_member.id)
      end

      before do
        renewal_enrollment.update_attributes(aasm_state: "renewing_coverage_selected")
        renewal_enrollment.hbx_enrollment_members << new_member
        expired_enrollment.update_attributes(aasm_state: :coverage_selected)
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
      end

      it 'should not cancel active renewed enrollment' do
        expect(renewal_enrollment.aasm_state).to eq "renewing_coverage_selected"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
        expect(subject).to be_success
        renewal_enrollment2.reload
        renewal_enrollment.reload
        expect(renewal_enrollment.aasm_state).to eq "renewing_coverage_selected"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
      end
    end

    context "should not cancel member drop active renewed enrollment on terminating active coverage" do
      let!(:new_person) { FactoryBot.create(:person, :with_consumer_role)}
      let!(:new_fam_member) { FactoryBot.create(:family_member, family: family, person: new_person) }
      let!(:new_member) do
        FactoryBot.create(:hbx_enrollment_member,
                          hbx_enrollment: expired_enrollment,
                          applicant_id: new_fam_member.id)
      end

      before do
        renewal_enrollment.update_attributes(aasm_state: "renewing_coverage_selected")
        expired_enrollment.update_attributes(aasm_state: :coverage_selected)
        allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
      end

      it 'should not cancel active renewed enrollment' do
        expect(renewal_enrollment.aasm_state).to eq "renewing_coverage_selected"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
        expect(subject).to be_success
        renewal_enrollment2.reload
        renewal_enrollment.reload
        expect(renewal_enrollment.aasm_state).to eq "renewing_coverage_selected"
        expect(renewal_enrollment2.aasm_state).to eq "coverage_selected"
      end
    end
  end

  describe "Should throw an error when the enrollment is not ivl " do
    before do
      expired_enrollment.update_attributes(kind: :employer_sponsored)
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
    end

    include_context 'family with previous enrollment for termination and passive renewal'
    let(:params) { expired_enrollment }

    it 'should cancel renewal enrollment when passed an active enrollment' do
      expect(subject).not_to be_success
      expect(subject.failure).to eq "Given enrollment is not IVL by kind"
    end
  end

  describe "Should throw an error when the enrollment is shopping " do
    before do
      expired_enrollment.update_attributes(aasm_state: :shopping)
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
    end

    include_context 'family with previous enrollment for termination and passive renewal'
    let(:params) { expired_enrollment }

    it 'should cancel renewal enrollment when passed an active enrollment' do
      expect(subject).not_to be_success
      expect(subject.failure).to eq "Given enrollment is a shopping enrollment by aasm_state"
    end
  end

  describe "Should system is not under oe period " do
    before do
      expired_enrollment.update_attributes(aasm_state: :coverage_selected)
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 9, 1))
    end

    include_context 'family with previous enrollment for termination and passive renewal'
    let(:params) { expired_enrollment }

    it 'should cancel renewal enrollment when passed an active enrollment' do
      expect(subject).not_to be_success
      expect(subject.failure).to eq "System is not under open enrollment"
    end
  end
end
