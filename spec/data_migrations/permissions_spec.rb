require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "define_permissions")

describe DefinePermissions, dbclean: :after_each do
  subject { DefinePermissions.new(given_task_name, double(:current_scope => nil))}
  let(:roles) {%w{hbx_staff hbx_read_only hbx_csr_supervisor hbx_csr_tier2 hbx_csr_tier1 developer} }
  describe 'create permissions' do
    let(:given_task_name) {':initial_hbx'}
    before do
      Person.all.delete
      person= FactoryGirl.create(:person)
      role = FactoryGirl.create(:hbx_staff_role, person: person)
      subject.initial_hbx
    end
    it "creates permissions" do
      expect(Permission.count).to eq(6)
    	expect(Person.first.hbx_staff_role.subrole).to eq 'hbx_staff'
      expect(Permission.all.map(&:name)).to match_array roles
    end

    describe 'update permissions for hbx staff role' do
      let(:given_task_name) {':hbx_admin_can_complete_resident_application'}

      before do
        User.all.delete
        Person.all.delete
        person = FactoryGirl.create(:person)
        permission = FactoryGirl.create(:permission, :hbx_staff)
        role = FactoryGirl.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: permission.id)
        subject.hbx_admin_can_complete_resident_application
      end

      it "updates can_complete_resident_application to true" do
        expect(Person.all.count).to eq(1)
        expect(Person.first.hbx_staff_role.permission.can_complete_resident_application).to be true
      end
    end

    describe 'update permissions for hbx staff role to be able to view username and email' do
      let(:given_task_name) {':hbx_admin_can_add_view_username_and_email'}

      before do
        User.all.delete
        Person.all.delete
        @hbx_staff_person = FactoryGirl.create(:person)
        @hbx_read_only_person = FactoryGirl.create(:person)
        @hbx_csr_supervisor_person = FactoryGirl.create(:person)
        @hbx_csr_tier1_person = FactoryGirl.create(:person)
        @hbx_csr_tier2_person = FactoryGirl.create(:person)
        hbx_staff_role = FactoryGirl.create(:hbx_staff_role, person: @hbx_staff_person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
        hbx_read_only_role = FactoryGirl.create(:hbx_staff_role, person: @hbx_read_only_person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
        hbx_csr_supervisor_role = FactoryGirl.create(:hbx_staff_role, person: @hbx_csr_supervisor_person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
        hbx_csr_tier1_role = FactoryGirl.create(:hbx_staff_role, person: @hbx_csr_tier1_person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
        hbx_csr_tier2_role = FactoryGirl.create(:hbx_staff_role, person: @hbx_csr_tier2_person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
        subject.hbx_admin_can_view_username_and_email
      end

      it "updates can_view_username_and_email to true" do
        expect(Person.all.count).to eq(5)
        expect(@hbx_staff_person.hbx_staff_role.permission.can_view_username_and_email).to be true
        expect(@hbx_read_only_person.hbx_staff_role.permission.can_view_username_and_email).to be true
        expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_view_username_and_email).to be true
        expect(@hbx_csr_tier1_person.hbx_staff_role.permission.can_view_username_and_email).to be true
        expect(@hbx_csr_tier2_person.hbx_staff_role.permission.can_view_username_and_email).to be true
        #verifying that the rake task updated only the correct subroles
        expect(Permission.developer.can_add_sep).to be false
      end
    end

    describe 'update permissions for hbx staff role to add sep' do
      let(:given_task_name) {':hbx_admin_can_add_sep'}

      before do
        User.all.delete
        Person.all.delete
        @hbx_staff_person = FactoryGirl.create(:person)
        @hbx_read_only_person = FactoryGirl.create(:person)
        @hbx_csr_supervisor_person = FactoryGirl.create(:person)
        hbx_staff_role = FactoryGirl.create(:hbx_staff_role, person: @hbx_staff_person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
        hbx_read_only_role = FactoryGirl.create(:hbx_staff_role, person: @hbx_read_only_person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
        hbx_csr_supervisor_role = FactoryGirl.create(:hbx_staff_role, person: @hbx_csr_supervisor_person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
        subject.hbx_admin_can_add_sep
      end

      it "updates can_complete_resident_application to true" do
        expect(Person.all.count).to eq(3)
        expect(@hbx_staff_person.hbx_staff_role.permission.can_add_sep).to be true
        expect(@hbx_read_only_person.hbx_staff_role.permission.can_add_sep).to be false
        expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_add_sep).to be false
        #verifying that the rake task updated only the correct subroles
        expect(Permission.hbx_csr_tier1.can_add_sep).to be false
        expect(Permission.hbx_csr_tier2.can_add_sep).to be false
        expect(Permission.developer.can_add_sep).to be false
      end
    end
  end

  describe 'build test roles' do
    let(:given_task_name) {':build_test_roles'}
    before do
      User.all.delete
      Person.all.delete
      allow(Permission).to receive_message_chain('hbx_staff.id'){FactoryGirl.create(:permission, :hbx_staff).id}
      allow(Permission).to receive_message_chain('hbx_read_only.id'){FactoryGirl.create(:permission, :hbx_read_only).id}
      allow(Permission).to receive_message_chain('hbx_csr_supervisor.id'){FactoryGirl.create(:permission, :hbx_csr_supervisor).id}
      allow(Permission).to receive_message_chain('hbx_csr_tier2.id'){FactoryGirl.create(:permission,  :hbx_csr_tier2).id}
      allow(Permission).to receive_message_chain('hbx_csr_tier1.id'){FactoryGirl.create(:permission,  :hbx_csr_tier1).id}
      allow(Permission).to receive_message_chain('hbx_csr_tier1.id'){FactoryGirl.create(:permission,  :developer).id}
      subject.build_test_roles
    end
    it "creates permissions" do
      expect(User.all.count).to eq(6)
      expect(Person.all.count).to eq(6)
      expect(Person.all.map{|p|p.hbx_staff_role.subrole}).to match_array roles
    end
  end
end
