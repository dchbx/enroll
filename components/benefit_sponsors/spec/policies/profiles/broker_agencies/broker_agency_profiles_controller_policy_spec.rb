require "rails_helper"

module BenefitSponsors
  RSpec.describe Profiles::BrokerAgencies::BrokerAgencyProfilesControllerPolicy, dbclean: :after_each do
    let(:policy) { BenefitSponsors::Profiles::BrokerAgencies::BrokerAgencyProfilesControllerPolicy.new(user, nil) }
    let(:person) { FactoryGirl.create(:person) }

    context 'for a user with no role' do
      let(:user) { FactoryGirl.create(:user) }

      shared_examples_for "should not permit for invalid user" do |policy_type|
        it "should not permit" do
          expect(policy.send(policy_type)).to be false
        end
      end

      it_behaves_like "should not permit for invalid user", :family_index?
      it_behaves_like "should not permit for invalid user", :family_datatable?
      it_behaves_like "should not permit for invalid user", :index?
      it_behaves_like "should not permit for invalid user", :show?
      it_behaves_like "should not permit for invalid user", :staff_index?
    end

    context 'for a user with hbx staff role' do
      let(:user) { FactoryGirl.create(:user, :with_hbx_staff_role, person: person) }

      shared_examples_for "should permit for a user with hbx staff role" do |policy_type|
        it "should permit" do
          expect(policy.send(policy_type)).to be true
        end
      end

      it_behaves_like "should permit for a user with hbx staff role", :family_index?
      it_behaves_like "should permit for a user with hbx staff role", :family_datatable?
      it_behaves_like "should permit for a user with hbx staff role", :index?
      it_behaves_like "should permit for a user with hbx staff role", :show?
      it_behaves_like "should permit for a user with hbx staff role", :staff_index?
    end

    context 'for a user with broker role' do
      let(:user) { FactoryGirl.create(:user, :broker, person: person) }

      shared_examples_for "should permit for a user with broker role" do |policy_type|
        it "should permit" do
          expect(policy.send(policy_type)).to be true
        end
      end

      it_behaves_like "should permit for a user with broker role", :family_index?
      it_behaves_like "should permit for a user with broker role", :family_datatable?

      it "should not permit the user with broker role for index?" do
        expect(policy.send(:index?)).to be false
      end

      it "should not permit the user with broker role for show?" do
        expect(policy.show?).to be false
      end

      it "should not permit the user with broker role for staff_index?" do
        expect(policy.staff_index?).to be false
      end
    end

    context 'for a user with csr role' do
      let(:user) { FactoryGirl.create(:user, :csr, person: person) }

      shared_examples_for "should not permit for a user with csr role" do |policy_type|
        it "should not permit" do
          expect(policy.send(policy_type)).to be false
        end
      end

      it_behaves_like "should not permit for a user with csr role", :family_index?
      it_behaves_like "should not permit for a user with csr role", :family_datatable?

      it "should permit the user with csr role for index?" do
        expect(policy.send(:index?)).to be true
      end

      it "should permit the user with csr role for show?" do
        expect(policy.show?).to be true
      end

      it "should permit the user with csr role for staff_index?" do
        expect(policy.staff_index?).to be true
      end
    end
  end
end