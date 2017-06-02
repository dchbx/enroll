require "rails_helper"

describe Subscribers::OutofPocketCalculator do
  it "should subscribe to the correct event" do
    expect(Subscribers::OutofPocketCalculator.subscription_details).to eq ["acapi.info.events.employer.out_of_pocker_url_notifier"]
  end
  describe "given a message to handle" do
    let(:slug_event_handler) { double }
    let(:organization) { FactoryGirl.create(:organization) }
    let(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
    let(:resource_mapping) { ApplicationEventMapper.map_resource("EmployerProfile") }
    
    before :each do
      allow(Subscribers::OutofPocketCalculator).to receive(:new).and_return(slug_event_handler)
      Rails.application.config.acapi.add_subscription(Subscribers::OutofPocketCalculator)
    end

    it "should send events to the new subscription" do
      Rails.application.config.acapi.register_all_additional_subscriptions
      expect(slug_event_handler).to receive(:call).at_least(:once) do |e_name, e_start, e_end, msg_id, payload|
        expect(e_name).to eq "acapi.info.events.employer.out_of_pocker_url_notifier"
        expect(payload).to eq({ resource_mapping.identifier_key => employer_profile.send(resource_mapping.identifier_method).to_s} )
      end
      subscriber = Subscribers::OutofPocketCalculator.new
      subscriber.call("acapi.info.events.employer.out_of_pocker_url_notifier",nil,nil,nil,{ resource_mapping.identifier_key => employer_profile.send(resource_mapping.identifier_method).to_s} )
    end
  end
end