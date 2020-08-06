# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe EmployerProfilePolicy, dbclean: :after_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"
    let(:policy) { BenefitSponsors::EmployerProfilePolicy.new(user, benefit_sponsorship.organization.profiles.first) }
    let(:person) { FactoryBot.create(:person) }

    context 'for a user with no role' do
      let(:user) { FactoryBot.create(:user, person: person) }

      shared_examples_for "should not permit for invalid user" do |policy_type|
        it "should not permit" do
          expect(policy.send(policy_type)).not_to be true
        end
      end

      it_behaves_like "should not permit for invalid user", :show?
    end

    context 'for a user with ER role' do
      let(:user) { FactoryBot.create(:user, person: person) }
      let(:er_staff_role) { FactoryBot.create(:benefit_sponsor_employer_staff_role, benefit_sponsor_employer_profile_id: benefit_sponsorship.organization.employer_profile.id) }

      shared_examples_for "should not permit for invalid user" do |policy_type|
        it "should permit for active ER staff role" do
          person.employer_staff_roles << er_staff_role
          expect(policy.send(policy_type)).to be true
        end

        it "should not permit for inactive ER staff role" do
          er_staff_role.update_attributes(aasm_state: "is_closed")
          person.employer_staff_roles << er_staff_role
          expect(policy.send(policy_type)).not_to be true
        end
      end

      it_behaves_like "should not permit for invalid user", :show?
    end
  end
end
