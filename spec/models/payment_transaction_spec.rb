require 'rails_helper'

RSpec.describe PaymentTransaction, :type => :model, dbclean: :after_each do
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member_and_dependent) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state: 'shopping') }

  context 'with generated payment transactions' do
    it 'should set submitted_at' do
      test_payment_transaction = PaymentTransaction.build_payment_instance(hbx_enrollment)
      expect(test_payment_transaction.submitted_at).not_to eq nil
    end

    it 'should generate payment_transaction_id' do
      test_payment_transaction = PaymentTransaction.build_payment_instance(hbx_enrollment)
      expect(test_payment_transaction.payment_transaction_id).not_to eq nil
    end
  end

  context 'build_payment_instance' do
    subject { PaymentTransaction.build_payment_instance(hbx_enrollment) }

    it 'should build payment transaction with enrollment effective date' do
      expect(subject.enrollment_effective_date).to eq hbx_enrollment.effective_on
    end

    it 'should build payment transaction with transaction id' do
      expect(subject.payment_transaction_id.present?).to eq true
    end

    it 'should build payment transaction with enrollment_id' do
      expect(subject.enrollment_id).to eq hbx_enrollment.id
    end
  end
end
