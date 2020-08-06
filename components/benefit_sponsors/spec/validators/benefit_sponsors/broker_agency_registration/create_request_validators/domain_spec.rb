# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::BrokerAgencyRegistration::CreateRequestValidators::DOMAIN do
  let(:user) { double }
  let(:request) do
    instance_double(
      BenefitSponsors::Requests::BrokerAgencyProfileCreateRequest,
      office_locations: office_locations
    )
  end

  subject { BenefitSponsors::BrokerAgencyRegistration::CreateRequestValidators::DOMAIN.new.call(user: user, request: request) }

  let(:broker_is_claimable) { true }
  let(:office_locations) { [mailing_office_location] }

  let(:mailing_office_location) do
    instance_double(
      BenefitSponsors::Requests::OfficeLocation,
      kind: "mailing"
    )
  end

  before :each do
    allow(BenefitSponsors::Services::BrokerRegistrationService).to receive(
      :may_claim_broker_identity?
    ).with(
      user,
      request
    ).and_return(broker_is_claimable)
  end

  context "with valid data" do
    it "is valid" do
      expect(subject.success?).to be_truthy
    end
  end

  context "when the broker role may not be claimed" do
    let(:broker_is_claimable) { false }

    it "is invalid because of the broker identity information" do
      expect(subject.success?).to be_falsey
      expect(subject.errors.to_h).to have_key(:broker_person_identity_available)
    end
  end

  context "when there is more than one mailing office location" do
    let(:office_locations) { [mailing_office_location, mailing_office_location_2] }

    let(:mailing_office_location_2) do
      instance_double(
        BenefitSponsors::Requests::OfficeLocation,
        kind: "mailing"
      )
    end

    it "is invalid because more than one mailing office location" do
      expect(subject.success?).to be_falsey
      expect(subject.errors.to_h).to have_key(:only_one_mailing_office_location)
    end
  end
end