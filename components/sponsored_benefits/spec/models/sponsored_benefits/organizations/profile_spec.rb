# frozen_string_literal: true

require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits.rb"

module SponsoredBenefits
  RSpec.describe Organizations::Profile, type: :model ,:dbclean => :after_each do
    include_context 'set up broker agency profile for BQT, by using configuration settings'

    pending "add some examples to (or delete) #{__FILE__}"

    let!(:profile) {plan_design_proposal.profile}
    let!(:census_employee) {plan_design_census_employee}

    context 'census_employees' do
      it 'should return census employees' do
        expect(profile.class).to eq ::SponsoredBenefits::Organizations::AcaShopDcEmployerProfile #This is the inherited class of SponsoredBenefits::Organizations::Profile
        expect(profile.census_employees.count).to eq 1
      end
    end
  end
end