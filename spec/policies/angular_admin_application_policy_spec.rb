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
          approve_broker: false,
          approve_ga: false,
          view_admin_tabs: false,
          can_change_fein: false,
          modify_admin_tabs: false,
          can_access_user_account_tab: false,
          view_login_history: false,
          view_the_configuration_tab: false,
          view_personal_info_page: false
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
          approve_broker: true,
          approve_ga: true,
          view_admin_tabs: true,
          can_change_fein: true,
          modify_admin_tabs: true,
          can_access_user_account_tab: true,
          view_login_history: true,
          view_the_configuration_tab: true,
          view_personal_info_page: true
        }
      )
    end

    it "allows visit?" do
      expect(subject.visit?).to be_truthy
    end

  end
end