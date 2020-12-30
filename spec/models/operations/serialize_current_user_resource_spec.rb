require "rails_helper"

describe Operations::SerializeCurrentUserResource do
  let(:view_agency_staff_allowed) { true }
  let(:manage_agency_staff_allowed) { true }

  let(:operation) { described_class.new(user) }
  
  let(:permission_proxy) do
    instance_double(
      Admin::PermissionsProxy,
      view_agency_staff: view_agency_staff_allowed,
      manage_agency_staff: manage_agency_staff_allowed
    )
  end

  subject { operation.call }

  before :each do
    allow(Admin::PermissionsProxy).to receive(:new).with(user).and_return(permission_proxy)
  end

  describe "given a user with an oim id" do
    let(:oim_id) { "some_oim_id" }

    let(:user) do
      instance_double(
        User,
        oim_id: oim_id,
        email: nil
      )
    end

    it "serializes the oim_id as the account_name" do
      expect(subject[:account_name]).to eq oim_id
    end

    it "serializes view_agency_staff" do
      expect(subject[:view_agency_staff]).to eq view_agency_staff_allowed
    end
    it "serializes manage_agency_staff" do
      expect(subject[:manage_agency_staff]).to eq manage_agency_staff_allowed
    end
  end

  describe "given a user with an email" do
    let(:email) { "some_email" }

    let(:user) do
      instance_double(
        User,
        email: email
      )
    end

    it "serializes the email as the account_name" do
      expect(subject[:account_name]).to eq email
    end

    it "serializes view_agency_staff" do
      expect(subject[:view_agency_staff]).to eq view_agency_staff_allowed
    end
    it "serializes manage_agency_staff" do
      expect(subject[:manage_agency_staff]).to eq manage_agency_staff_allowed
    end
  end
end
