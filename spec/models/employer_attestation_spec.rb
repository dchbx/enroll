require 'rails_helper'

describe EmployerAttestation, dbclean: :after_each do

  context ".deny" do

    let(:start_on) { TimeKeeper.date_of_record.beginning_of_month }
    let(:plan_year) { FactoryGirl.create(:plan_year,aasm_state:'active') }
    let(:employer_profile) { FactoryGirl.create(:employer_profile,plan_years:[plan_year] )}
    let!(:employer_attestation) { FactoryGirl.create(:employer_attestation,employer_profile:employer_profile) }
  
    
    context '.terminate_employer' do

      context 'employer with active plan year' do

        it 'should reject document and terminate plan year' do
          employer_attestation.deny!
          expect(plan_year.aasm_state).to eq 'termination_pending'
          expect(plan_year.end_on).to eq TimeKeeper.date_of_record.end_of_month
          expect(plan_year.terminated_on).to eq TimeKeeper.date_of_record.end_of_month
        end
      end

      context 'employer with published plan year' do
        
        it 'should reject document and cancel plan year' do
          plan_year.update_attributes(start_on:TimeKeeper.date_of_record.beginning_of_month + 1.month, aasm_state:'enrolling')
          employer_attestation.deny!
          expect(plan_year.aasm_state).to eq 'canceled'
        end
      end
    end
  end

  context ".revert" do
    let(:employer_profile) { FactoryGirl.create(:employer_profile)}
    let!(:employer_attestation) { FactoryGirl.create(:employer_attestation,aasm_state:'denied',employer_profile:employer_profile) }
        
    it 'should revert employer_attestation from denied to unsubmitted state' do
      employer_attestation.revert!
      expect(employer_attestation.aasm_state).to eq 'unsubmitted'
    end

    it 'should revert employer_attestation from pending to unsubmitted state' do
      employer_attestation.update_attributes(aasm_state:'pending')
      employer_attestation.revert!
      expect(employer_attestation.aasm_state).to eq 'unsubmitted'
    end

    it 'should revert employer_attestation from submitted to unsubmitted state' do
      employer_attestation.update_attributes(aasm_state:'submitted')
      employer_attestation.revert!
      expect(employer_attestation.aasm_state).to eq 'unsubmitted'
    end
  end
end