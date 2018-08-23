require 'rails_helper'

RSpec.describe PaymentTransaction, :type => :model, dbclean: :after_each do

  context "with generated payment transactions" do
    let(:person) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let(:test_payment_transaction) {
      family.payment_transactions <<  PaymentTransaction.new
      family.payment_transactions.first.save!
      family.payment_transactions[0]
    }

    it "should set submitted_at" do
      expect(test_payment_transaction.submitted_at).not_to eq nil
    end

    it "should generate payment_transaction_id" do
      expect(test_payment_transaction.payment_transaction_id).not_to eq nil
    end
  end
end
