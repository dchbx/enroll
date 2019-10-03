require "rails_helper"

module BenefitSponsors
  RSpec.describe Profiles::GeneralAgencies::GeneralAgencyProfilesControllerPolicy, dbclean: :after_each do
    let(:policy) { BenefitSponsors::Profiles::GeneralAgencies::GeneralAgencyProfilesControllerPolicy.new(user, nil) }
    let(:person) { FactoryBot.create(:person) }

    context 'for a user with no role' do
      let(:user) { FactoryBot.create(:user) }

      shared_examples_for "should not permit for invalid user" do |policy_type|
        it "should not permit" do
          expect(policy.send(policy_type)).not_to be true
        end
      end

      it_behaves_like "should not permit for invalid user", :show?
      it_behaves_like "should not permit for invalid user", :edit_staff?
      it_behaves_like "should not permit for invalid user", :update_staff?
      it_behaves_like "should not permit for invalid user", :staffs?
      it_behaves_like "should not permit for invalid user", :staff_index?
    end

    context 'for a user with hbx staff role' do
      let(:user) { FactoryBot.create(:user, :with_hbx_staff_role, person: person) }

      shared_examples_for "should permit for a user with hbx staff role" do |policy_type|
        it "should permit" do
          expect(policy.send(policy_type)).to be true
        end
      end

      it_behaves_like "should permit for a user with hbx staff role", :show?
      it_behaves_like "should permit for a user with hbx staff role", :edit_staff?
      it_behaves_like "should permit for a user with hbx staff role", :update_staff?
      it_behaves_like "should permit for a user with hbx staff role", :staffs?
      it_behaves_like "should permit for a user with hbx staff role", :staff_index?
    end

    context 'for a user with general agency role' do
      let(:user) { FactoryBot.create(:user, :general, person: person) }

      shared_examples_for "should permit for a user with general agency role" do |policy_type|
        it "should permit" do
          allow(user).to receive(:has_general_agency_staff_role?) {true}
          expect(policy.send(policy_type)).to be true
        end
      end

      it_behaves_like "should permit for a user with general agency role", :families?
      # it_behaves_like "should permit for a user with broker role", :family_datatable?

      # it "should not permit the user with broker role for index?" do
      #   expect(policy.send(:index?)).to be false
      # end

      it "should not permit the user with general agency role for show?" do
        expect(policy.show?).to be false
      end

      it "should not permit the user with general agency role for staff_index?" do
        expect(policy.staff_index?).to be false
      end
    end
  end
end
