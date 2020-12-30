require "rails_helper"

describe AngularAdminApplicationPolicy do

  let(:application_profile) { double }

  subject do
    AngularAdminApplicationPolicy.new(user, application_profile)
  end

  describe "given a non-adminstrative user" do

    let(:user) do
      instance_double(
        User,
        {
          :has_hbx_staff_role? => false
        }
      )
    end

    it "denies visit?" do
      expect(subject.visit?).to be_falsey
    end

  end

  describe "given an adminstrative user, but with no assigned permission" do

    let(:user) do
      instance_double(
        User,
        {
          :has_hbx_staff_role? => true,
          :person => person
        }
      )
    end

    let(:person) do
      instance_double(
        Person,
        {
          :hbx_staff_role => hbx_staff_role
        }
      )
    end

    let(:hbx_staff_role) do
      instance_double(
        HbxStaffRole,
        {
          :permission => nil
        }
      )
    end

    it "denies visit?" do
      expect(subject.visit?).to be_falsey
    end

  end

  describe "given an adminstrative user, with insufficient permissions" do

    let(:user) do
      instance_double(
        User,
        {
          :has_hbx_staff_role? => true,
          :person => person
        }
      )
    end

    let(:person) do
      instance_double(
        Person,
        {
          :hbx_staff_role => hbx_staff_role
        }
      )
    end

    let(:hbx_staff_role) do
      instance_double(
        HbxStaffRole,
        {
          :permission => permission
        }
      )
    end

    let(:permission) do
      instance_double(
        Permission,
        {
          view_agency_staff: false
        }
      )
    end

    it "denies visit?" do
      expect(subject.visit?).to be_falsey
    end

  end

  describe "given an adminstrative user, with sufficient permissions" do

    let(:user) do
      instance_double(
        User,
        {
          :has_hbx_staff_role? => true,
          :person => person
        }
      )
    end

    let(:person) do
      instance_double(
        Person,
        {
          :hbx_staff_role => hbx_staff_role
        }
      )
    end

    let(:hbx_staff_role) do
      instance_double(
        HbxStaffRole,
        {
          :permission => permission
        }
      )
    end

    let(:permission) do
      instance_double(
        Permission,
        {
          view_agency_staff: true
        }
      )
    end

    it "allows visit?" do
      expect(subject.visit?).to be_truthy
    end

  end
end