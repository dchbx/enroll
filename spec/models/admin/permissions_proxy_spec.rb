require "rails_helper"

RSpec.shared_examples "a permission set allowed no actions" do
  it "may not view agency staff" do
    expect(subject.view_agency_staff).to be_falsey
  end

  it "may not manage agency staff" do
    expect(subject.manage_agency_staff).to be_falsey
  end
end

describe Admin::PermissionsProxy do

  subject { described_class.new(user) }

  describe "a user with no person" do
    let(:user) do
      instance_double(
        User,
        person: nil
      )
    end

    it_behaves_like "a permission set allowed no actions"
  end

  describe "a user with a person but no staff role" do
    let(:person) do
      instance_double(
        Person,
        hbx_staff_role: nil
      )
    end

    let(:user) do
      instance_double(
        User,
        person: person
      )
    end

    it_behaves_like "a permission set allowed no actions"
  end

  describe "a user with a staff role but no permission assigned" do
    let(:hbx_staff_role) do
      instance_double(
        HbxStaffRole,
        permission: nil
      )
    end

    let(:person) do
      instance_double(
        Person,
        hbx_staff_role: hbx_staff_role
      )
    end

    let(:user) do
      instance_double(
        User,
        person: person
      )
    end

    it_behaves_like "a permission set allowed no actions"
  end

  describe "a user with a permission assigned, but nothing allowed" do
    let(:permission) do
      instance_double(
        Permission,
        view_agency_staff: false,
        manage_agency_staff: false
      )
    end

    let(:hbx_staff_role) do
      instance_double(
        HbxStaffRole,
        permission: permission
      )
    end

    let(:person) do
      instance_double(
        Person,
        hbx_staff_role: hbx_staff_role
      )
    end

    let(:user) do
      instance_double(
        User,
        person: person
      )
    end

    it_behaves_like "a permission set allowed no actions"
  end

  describe "a user with a permission assigned, and allowed everything" do
    let(:permission) do
      instance_double(
        Permission,
        view_agency_staff: true,
        manage_agency_staff: true
      )
    end

    let(:hbx_staff_role) do
      instance_double(
        HbxStaffRole,
        permission: permission
      )
    end

    let(:person) do
      instance_double(
        Person,
        hbx_staff_role: hbx_staff_role
      )
    end

    let(:user) do
      instance_double(
        User,
        person: person
      )
    end

    it "can view agency staff" do
      expect(subject.view_agency_staff).to be_truthy
    end
  
    it "can manage agency staff" do
      expect(subject.manage_agency_staff).to be_truthy
    end
  end
end