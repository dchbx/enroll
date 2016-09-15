require "rails_helper"

describe Subscribers::DefaultGaChanged do
  it "should subscribe to the correct event" do
    expect(Subscribers::DefaultGaChanged.subscription_details).to eq ["acapi.info.events.broker.default_ga_changed"]
  end

  describe "given a message to handle" do
    let(:organization) { FactoryGirl.create(:organization) }
    let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }
    let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile, organization: organization) }
    let(:person) { FactoryGirl.create(:person, :with_broker_role) }
    let(:broker_role) { person.broker_role }
    let(:hbx_id) { person.hbx_id }
    let(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }

    before :each do
      broker_role.approve
      broker_role.broker_agency_accept
      broker_role.broker_agency_profile_id = broker_agency_profile.id
      broker_role.save
      employer_profile.hire_general_agency(general_agency_profile, broker_role.id)
      employer_profile.save
      allow(Organization).to receive(:by_broker_agency_profile).and_return(orgs)
    end

    context "that has a hbx_id without default_ga" do
      let(:message) { { "broker_id" => hbx_id, "pre_default_ga_id" => general_agency_profile.id.to_s } }
      let(:orgs) { double }

      it "should not do clear without pre_default_ga_id" do
        allow(orgs).to receive(:by_general_agency_profile).and_return([organization])
        expect(Organization).to receive(:by_broker_agency_profile).with(broker_agency_profile.id)
        expect(subject).not_to receive(:send_general_agency_assign_msg)
        subject.call(nil, nil, nil, nil, message.except("pre_default_ga_id"))
      end

      it "should do clear with pre_default_ga_id" do
        allow(orgs).to receive(:by_general_agency_profile).and_return([organization])
        expect(Organization).to receive(:by_broker_agency_profile).with(broker_agency_profile.id)
        expect(subject).to receive(:send_general_agency_assign_msg)
        subject.call(nil, nil, nil, nil, message)
        expect(employer_profile.active_general_agency_account).to eq nil
      end
    end

    context "that has a hbx_id with default_ga" do
      let(:message) { { "broker_id" => hbx_id, "pre_default_ga_id" => general_agency_profile.id.to_s } }
      let(:new_ga) { FactoryGirl.create(:general_agency_profile) }
      let(:orgs) { [organization] }
      before :each do
        broker_agency_profile.default_general_agency_profile = new_ga
        broker_agency_profile.save
      end

      it "should do change" do
        expect(employer_profile.active_general_agency_account.general_agency_profile).to eq general_agency_profile
      end

      it "should do change when employer_profile does not have active general_agency_profile" do
        employer_profile.fire_general_agency!
        expect(employer_profile.active_general_agency_account).to eq nil

        expect(Organization).to receive(:by_broker_agency_profile).with(broker_agency_profile.id)
        expect(subject).to receive(:send_general_agency_assign_msg)
        subject.call(nil, nil, nil, nil, message)
        expect(employer_profile.active_general_agency_account.general_agency_profile).to eq new_ga
      end

      it "should do not change when employer_profile have active general_agency_profile" do
        expect(employer_profile.active_general_agency_account.general_agency_profile).to eq general_agency_profile

        expect(Organization).to receive(:by_broker_agency_profile).with(broker_agency_profile.id)
        expect(subject).not_to receive(:send_general_agency_assign_msg)
        subject.call(nil, nil, nil, nil, message)
        expect(employer_profile.active_general_agency_account.general_agency_profile).to eq general_agency_profile
      end
    end
  end
end
