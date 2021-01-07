require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "define_permissions")

describe DefinePermissions, dbclean: :after_each do
  subject { DefinePermissions.new(given_task_name, double(:current_scope => nil))}
  let(:roles) {%w{hbx_staff hbx_read_only hbx_csr_supervisor hbx_tier3 hbx_csr_tier2 hbx_csr_tier1 developer super_admin} }
  describe 'create permissions' do
    let(:given_task_name) {':initial_hbx'}

    before do
      Person.delete_all
      person = FactoryBot.create(:person)
      role = FactoryBot.create(:hbx_staff_role, person: person)
      subject.initial_hbx
    end
    it "creates permissions" do
      expect(Permission.all.to_a.count).to eq(8)
      #expect(Person.first.hbx_staff_role.subrole).to eq 'hbx_staff'
      expect(Permission.all.map(&:name)).to match_array roles
    end

    context 'update permissions for hbx staff role', dbclean: :after_each do
      let(:given_task_name) {':hbx_admin_can_complete_resident_application'}

      before do
        User.delete_all
        Person.delete_all
        person = FactoryBot.create(:person)
        permission = FactoryBot.create(:permission, :hbx_staff)
        role = FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: permission.id)
        subject.hbx_admin_can_complete_resident_application
      end

      it "updates can_complete_resident_application to true" do
        expect(Person.all.to_a.count).to eq(1)
        expect(Person.first.hbx_staff_role.permission.can_complete_resident_application).to be true
      end
    end

    describe 'update permissions for hbx staff role to be able to view username and email' do
      let(:given_task_name) {':hbx_admin_can_add_view_username_and_email'}
      let(:given_task_name) {':hbx_admin_can_access_pay_now'}

      before do
        User.destroy_all
        Person.destroy_all
        @hbx_staff_person = FactoryBot.create(:person)
        @super_admin = FactoryBot.create(:person)
        @hbx_tier3 = FactoryBot.create(:person)
        @hbx_read_only_person = FactoryBot.create(:person)
        @hbx_csr_supervisor_person = FactoryBot.create(:person)
        @hbx_csr_tier1_person = FactoryBot.create(:person)
        @hbx_csr_tier2_person = FactoryBot.create(:person)
        hbx_staff_role = FactoryBot.create(:hbx_staff_role, person: @hbx_staff_person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
        hbx_read_only_role = FactoryBot.create(:hbx_staff_role, person: @hbx_read_only_person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
        hbx_csr_supervisor_role = FactoryBot.create(:hbx_staff_role, person: @hbx_csr_supervisor_person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
        hbx_csr_tier1_role = FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier1_person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
        hbx_csr_tier2_role = FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier2_person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
        super_admin = FactoryBot.create(:hbx_staff_role, person: @super_admin, subrole: "super_admin", permission_id: Permission.super_admin.id)
        hbx_tier3 = FactoryBot.create(:hbx_staff_role, person: @hbx_tier3, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
        subject.hbx_admin_can_view_username_and_email
      end

      it "updates can_access_pay_now to true" do
        subject.hbx_admin_can_access_pay_now
        expect(Person.all.to_a.count).to eq(7)
        expect(@hbx_staff_person.hbx_staff_role.permission.can_access_pay_now).to be true
        expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_access_pay_now).to be true
        expect(@hbx_csr_tier1_person.hbx_staff_role.permission.can_access_pay_now).to be true
        expect(@hbx_csr_tier2_person.hbx_staff_role.permission.can_access_pay_now).to be true
      end

      it "updates can_view_username_and_email to true" do
        expect(Person.all.to_a.count).to eq(7)
        expect(@hbx_staff_person.hbx_staff_role.permission.can_view_username_and_email).to be true
        expect(@super_admin.hbx_staff_role.permission.can_view_username_and_email).to be true
        expect(@hbx_tier3.hbx_staff_role.permission.can_view_username_and_email).to be true
        expect(@hbx_read_only_person.hbx_staff_role.permission.can_view_username_and_email).to be true
        expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_view_username_and_email).to be true
        expect(@hbx_csr_tier1_person.hbx_staff_role.permission.can_view_username_and_email).to be true
        expect(@hbx_csr_tier2_person.hbx_staff_role.permission.can_view_username_and_email).to be true
        #verifying that the rake task updated only the correct subroles
        expect(Permission.developer.can_add_sep).to be false
      end
    end

    describe 'update permissions for hbx staff role to be able to access user accounts tab' do
      let(:given_task_name) {':hbx_admin_can_access_user_account_tab'}

      before do
        User.all.delete
        Person.all.delete
        @hbx_staff_person = FactoryBot.create(:person)
        @super_admin = FactoryBot.create(:person)
        @hbx_tier3 = FactoryBot.create(:person)
        @hbx_read_only_person = FactoryBot.create(:person)
        @hbx_csr_supervisor_person = FactoryBot.create(:person)
        @hbx_csr_tier1_person = FactoryBot.create(:person)
        @hbx_csr_tier2_person = FactoryBot.create(:person)
        FactoryBot.create(:hbx_staff_role, person: @hbx_staff_person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_read_only_person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_csr_supervisor_person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier1_person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier2_person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
        FactoryBot.create(:hbx_staff_role, person: @super_admin, subrole: "super_admin", permission_id: Permission.super_admin.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_tier3, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
        subject.hbx_admin_can_access_user_account_tab
      end

      it "updates can_access_user_account_tab to true" do
        expect(Person.all.to_a.count).to eq(7)
        expect(@hbx_staff_person.hbx_staff_role.permission.can_access_user_account_tab).to be true
        expect(@super_admin.hbx_staff_role.permission.can_access_user_account_tab).to be true
        expect(@hbx_tier3.hbx_staff_role.permission.can_access_user_account_tab).to be true
        expect(@hbx_read_only_person.hbx_staff_role.permission.can_access_user_account_tab).to be false
        expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_access_user_account_tab).to be false
        expect(@hbx_csr_tier1_person.hbx_staff_role.permission.can_access_user_account_tab).to be false
        expect(@hbx_csr_tier2_person.hbx_staff_role.permission.can_access_user_account_tab).to be false
      end
    end

    describe 'update permissions for hbx staff role to be able to access send secure message' do
      let(:given_task_name) {':hbx_admin_can_send_secure_message'}

      before do
        User.all.delete
        Person.all.delete
        @hbx_staff_person = FactoryBot.create(:person)
        @super_admin = FactoryBot.create(:person)
        @hbx_tier3 = FactoryBot.create(:person)
        @hbx_read_only_person = FactoryBot.create(:person)
        @hbx_csr_supervisor_person = FactoryBot.create(:person)
        @hbx_csr_tier1_person = FactoryBot.create(:person)
        @hbx_csr_tier2_person = FactoryBot.create(:person)
        FactoryBot.create(:hbx_staff_role, person: @hbx_staff_person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_read_only_person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_csr_supervisor_person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier1_person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier2_person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
        FactoryBot.create(:hbx_staff_role, person: @super_admin, subrole: "super_admin", permission_id: Permission.super_admin.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_tier3, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
        subject.hbx_admin_can_send_secure_message
      end

      it "updates can_send_secure_message to true" do
        expect(Person.all.to_a.count).to eq(7)
        expect(@hbx_staff_person.hbx_staff_role.permission.can_send_secure_message).to be false
        expect(@super_admin.hbx_staff_role.permission.can_send_secure_message).to be true
        expect(@hbx_tier3.hbx_staff_role.permission.can_send_secure_message).to be true
        expect(@hbx_read_only_person.hbx_staff_role.permission.can_send_secure_message).to be false
        expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_send_secure_message).to be false
        expect(@hbx_csr_tier1_person.hbx_staff_role.permission.can_send_secure_message).to be false
        expect(@hbx_csr_tier2_person.hbx_staff_role.permission.can_send_secure_message).to be false
      end
    end

    describe 'update permissions for hbx staff role to be able to access age off included checkbox' do
      let(:given_task_name) {':hbx_admin_can_access_age_off_excluded'}

      before do
        User.all.delete
        Person.all.delete
        @hbx_staff_person = FactoryBot.create(:person)
        @super_admin = FactoryBot.create(:person)
        @hbx_tier3 = FactoryBot.create(:person)
        @hbx_read_only_person = FactoryBot.create(:person)
        @hbx_csr_supervisor_person = FactoryBot.create(:person)
        @hbx_csr_tier1_person = FactoryBot.create(:person)
        @hbx_csr_tier2_person = FactoryBot.create(:person)
        FactoryBot.create(:hbx_staff_role, person: @hbx_staff_person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_read_only_person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_csr_supervisor_person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier1_person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier2_person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
        FactoryBot.create(:hbx_staff_role, person: @super_admin, subrole: "super_admin", permission_id: Permission.super_admin.id)
        FactoryBot.create(:hbx_staff_role, person: @hbx_tier3, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
        subject.hbx_admin_can_access_age_off_excluded
      end

      it "update can_access_age_off_excluded to true for tier1 & tier2 roles" do
        expect(Person.all.count).to eq(7)
        expect(@hbx_staff_person.hbx_staff_role.permission.can_access_age_off_excluded).to be true
        expect(@super_admin.hbx_staff_role.permission.can_access_age_off_excluded).to be true
        expect(@hbx_tier3.hbx_staff_role.permission.can_access_age_off_excluded).to be true
        expect(@hbx_read_only_person.hbx_staff_role.permission.can_access_age_off_excluded).to be false
        expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_access_age_off_excluded).to be true
        expect(@hbx_csr_tier1_person.hbx_staff_role.permission.can_access_age_off_excluded).to be true
        expect(@hbx_csr_tier2_person.hbx_staff_role.permission.can_access_age_off_excluded).to be true
      end
    end

    describe 'update permissions for super admin role to be able to force publish' do
      let(:given_task_name) {':hbx_admin_can_force_publish'}

      before do
        User.all.delete
        Person.all.delete
      end

      context "of an hbx super admin" do
        let(:hbx_super_admin) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "super_admin", permission_id: Permission.super_admin.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_super_admin.hbx_staff_role.permission.can_force_publish).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_force_publish
          end

          it 'returns true' do
            expect(hbx_super_admin.hbx_staff_role.permission.can_force_publish).to be true
          end
        end
      end

      context "of an hbx staff" do
        let(:hbx_staff) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_staff.hbx_staff_role.permission.can_force_publish).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_force_publish
          end

          it 'returns false' do
            expect(hbx_staff.hbx_staff_role.permission.can_force_publish).to be false
          end
        end
      end

      context "of an hbx read only" do
        let(:hbx_read_only) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_read_only.hbx_staff_role.permission.can_force_publish).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_force_publish
          end

          it 'returns false' do
            expect(hbx_read_only.hbx_staff_role.permission.can_force_publish).to be false
          end
        end
      end

      context "of an hbx csr supervisor" do
        let(:hbx_csr_supervisor) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_supervisor.hbx_staff_role.permission.can_force_publish).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_force_publish
          end

          it 'returns false' do
            expect(hbx_csr_supervisor.hbx_staff_role.permission.can_force_publish).to be false
          end
        end
      end

      context "of an hbx csr tier1" do
        let(:hbx_csr_tier1) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_tier1.hbx_staff_role.permission.can_force_publish).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_force_publish
          end

          it 'returns false' do
            expect(hbx_csr_tier1.hbx_staff_role.permission.can_force_publish).to be false
          end
        end
      end

      context "of an hbx csr tier2" do
        let(:hbx_csr_tier2) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_tier2.hbx_staff_role.permission.can_force_publish).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_force_publish
          end

          it 'returns false' do
            expect(hbx_csr_tier2.hbx_staff_role.permission.can_force_publish).to be false
          end
        end
      end

      context "of an hbx tier3" do
        let(:hbx_tier3) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_tier3.hbx_staff_role.permission.can_force_publish).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_force_publish
          end

          it 'returns true' do
            expect(hbx_tier3.hbx_staff_role.permission.can_force_publish).to be true
          end
        end
      end

      context "of an hbx staff" do
        let(:hbx_staff) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_staff.hbx_staff_role.permission.can_force_publish).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_force_publish
          end

          it 'returns false' do
            expect(hbx_staff.hbx_staff_role.permission.can_force_publish).to be false
          end
        end
      end

      context "of an hbx staff" do
        let(:developer) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "developer", permission_id: Permission.developer.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(developer.hbx_staff_role.permission.can_force_publish).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_force_publish
          end

          it 'returns false' do
            expect(developer.hbx_staff_role.permission.can_force_publish).to be false
          end
        end
      end
    end

    describe 'update permissions for super admin role to be able to change FEIN' do
      let(:given_task_name) {':hbx_admin_can_change_fein'}

      before do
        User.all.delete
        Person.all.delete
      end

      context "of an hbx super admin" do
        let(:hbx_super_admin) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "super_admin", permission_id: Permission.super_admin.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_super_admin.hbx_staff_role.permission.can_change_fein).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_change_fein
          end

          it 'returns true' do
            expect(hbx_super_admin.hbx_staff_role.permission.can_change_fein).to be true
          end
        end
      end

      context "of an hbx staff" do
        let(:hbx_staff) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_staff.hbx_staff_role.permission.can_change_fein).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_change_fein
          end

          it 'returns false' do
            expect(hbx_staff.hbx_staff_role.permission.can_change_fein).to be false
          end
        end
      end

      context "of an hbx read only" do
        let(:hbx_read_only) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_read_only.hbx_staff_role.permission.can_change_fein).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_change_fein
          end

          it 'returns false' do
            expect(hbx_read_only.hbx_staff_role.permission.can_change_fein).to be false
          end
        end
      end

      context "of an hbx csr supervisor" do
        let(:hbx_csr_supervisor) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_supervisor.hbx_staff_role.permission.can_change_fein).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_change_fein
          end

          it 'returns false' do
            expect(hbx_csr_supervisor.hbx_staff_role.permission.can_change_fein).to be false
          end
        end
      end

      context "of an hbx csr tier1" do
        let(:hbx_csr_tier1) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_tier1.hbx_staff_role.permission.can_change_fein).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_change_fein
          end

          it 'returns false' do
            expect(hbx_csr_tier1.hbx_staff_role.permission.can_change_fein).to be false
          end
        end
      end

      context "of an hbx csr tier2" do
        let(:hbx_csr_tier2) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_tier2.hbx_staff_role.permission.can_change_fein).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_change_fein
          end

          it 'returns false' do
            expect(hbx_csr_tier2.hbx_staff_role.permission.can_change_fein).to be false
          end
        end
      end

      context "of an hbx tier3" do
        let(:hbx_tier3) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_tier3.hbx_staff_role.permission.can_change_fein).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_change_fein
          end

          it 'returns false' do
            expect(hbx_tier3.hbx_staff_role.permission.can_change_fein).to be true
          end
        end
      end

      context "of an hbx developer" do
        let(:developer) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "developer", permission_id: Permission.developer.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(developer.hbx_staff_role.permission.can_change_fein).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_change_fein
          end

          it 'returns false' do
            expect(developer.hbx_staff_role.permission.can_change_fein).to be false
          end
        end
      end
    end

    describe 'update permissions for hbx staff role to be able to view  application types' do
      let(:given_task_name) {':hbx_admin_can_view_application_types'}
      before do
        User.all.delete
        Person.all.delete
        @hbx_staff_person = FactoryBot.create(:person)
        @hbx_csr_supervisor_person = FactoryBot.create(:person)
        @hbx_csr_tier1_person = FactoryBot.create(:person)
        @hbx_csr_tier2_person = FactoryBot.create(:person)
        hbx_staff_role = FactoryBot.create(:hbx_staff_role, person: @hbx_staff_person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
        hbx_csr_supervisor_role = FactoryBot.create(:hbx_staff_role, person: @hbx_csr_supervisor_person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
        hbx_csr_tier1_role = FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier1_person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
        hbx_csr_tier2_role = FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier2_person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
        subject.hbx_admin_can_view_application_types
      end

      it "updates can_view_application_types to true" do
        expect(Person.all.to_a.count).to eq(4)
        expect(@hbx_staff_person.hbx_staff_role.permission.can_view_application_types).to be true
        expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_view_application_types).to be false
        expect(@hbx_csr_tier1_person.hbx_staff_role.permission.can_view_application_types).to be false
        expect(@hbx_csr_tier2_person.hbx_staff_role.permission.can_view_application_types).to be false
        #verifying that the rake task updated only the correct subroles
        expect(Permission.developer.can_view_application_types).to be false
      end
    end


    describe 'update permissions for hbx staff role to add sep' do
      let(:given_task_name) {':hbx_admin_can_add_sep'}

      before do
        User.all.delete
        Person.all.delete
        @hbx_staff_person = FactoryBot.create(:person)
        @super_admin = FactoryBot.create(:person)
        @hbx_tier3 = FactoryBot.create(:person)
        @hbx_read_only_person = FactoryBot.create(:person)
        @hbx_csr_supervisor_person = FactoryBot.create(:person)
        hbx_staff_role = FactoryBot.create(:hbx_staff_role, person: @hbx_staff_person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
        hbx_read_only_role = FactoryBot.create(:hbx_staff_role, person: @hbx_read_only_person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
        hbx_csr_supervisor_role = FactoryBot.create(:hbx_staff_role, person: @hbx_csr_supervisor_person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
        super_admin = FactoryBot.create(:hbx_staff_role, person: @super_admin, subrole: "super_admin", permission_id: Permission.super_admin.id)
        hbx_tier3 = FactoryBot.create(:hbx_staff_role, person: @hbx_tier3, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
        subject.hbx_admin_can_add_sep
      end

      it "updates can_complete_resident_application to true" do
        expect(Person.all.to_a.count).to eq(5)
        expect(@hbx_staff_person.hbx_staff_role.permission.can_add_sep).to be true
        expect(@super_admin.hbx_staff_role.permission.can_add_sep).to be true
        expect(@hbx_tier3.hbx_staff_role.permission.can_add_sep).to be true
        expect(@hbx_read_only_person.hbx_staff_role.permission.can_add_sep).to be false
        expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_add_sep).to be false
        #verifying that the rake task updated only the correct subroles
        expect(Permission.hbx_csr_tier1.can_add_sep).to be false
        expect(Permission.hbx_csr_tier2.can_add_sep).to be false
        expect(Permission.developer.can_add_sep).to be false
      end
    end

    describe 'update permissions for hbx tier3 can extend open enrollment' do
      let(:given_task_name) {':hbx_admin_can_extend_open_enrollment'}
      before do
        User.all.delete
        Person.all.delete
      end
      context "of an hbx tier3" do
        let(:hbx_tier3) do
          FactoryBot.create(:person, :with_hbx_staff_role).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_tier3.hbx_staff_role.permission.can_extend_open_enrollment).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_extend_open_enrollment
          end

          it 'returns true' do
            expect(hbx_tier3.hbx_staff_role.permission.can_extend_open_enrollment).to be true
          end
        end
      end
    end

    describe 'update permissions for super admin role to be able to create benefit application' do
      let(:given_task_name) {':hbx_admin_can_create_benefit_application'}

      before do
        User.all.delete
        Person.all.delete
      end

      context "of an hbx super admin" do
        let(:hbx_super_admin) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "super_admin", permission_id: Permission.super_admin.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_super_admin.hbx_staff_role.permission.can_create_benefit_application).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_create_benefit_application
          end

          it 'returns true' do
            expect(hbx_super_admin.hbx_staff_role.permission.can_create_benefit_application).to be true
          end
        end
      end

      context "of an hbx staff" do
        let(:hbx_staff) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_staff.hbx_staff_role.permission.can_create_benefit_application).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_create_benefit_application
          end

          it 'returns false' do
            expect(hbx_staff.hbx_staff_role.permission.can_create_benefit_application).to be false
          end
        end
      end

      context "of an hbx read only" do
        let(:hbx_read_only) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_read_only.hbx_staff_role.permission.can_create_benefit_application).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_create_benefit_application
          end

          it 'returns false' do
            expect(hbx_read_only.hbx_staff_role.permission.can_create_benefit_application).to be false
          end
        end
      end

      context "of an hbx csr supervisor" do
        let(:hbx_csr_supervisor) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_supervisor.hbx_staff_role.permission.can_create_benefit_application).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_create_benefit_application
          end

          it 'returns false' do
            expect(hbx_csr_supervisor.hbx_staff_role.permission.can_create_benefit_application).to be false
          end
        end
      end

      context "of an hbx csr tier1" do
        let(:hbx_csr_tier1) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_tier1.hbx_staff_role.permission.can_create_benefit_application).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_create_benefit_application
          end

          it 'returns false' do
            expect(hbx_csr_tier1.hbx_staff_role.permission.can_create_benefit_application).to be false
          end
        end
      end

      context "of an hbx csr tier2" do
        let(:hbx_csr_tier2) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_tier2.hbx_staff_role.permission.can_create_benefit_application).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_create_benefit_application
          end

          it 'returns false' do
            expect(hbx_csr_tier2.hbx_staff_role.permission.can_create_benefit_application).to be false
          end
        end
      end

      context "of an hbx tier3" do
        let(:hbx_tier3) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_tier3.hbx_staff_role.permission.can_create_benefit_application).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_create_benefit_application
          end

          it 'returns true' do
            expect(hbx_tier3.hbx_staff_role.permission.can_create_benefit_application).to be true
          end
        end
      end

      context "of an hbx staff" do
        let(:hbx_staff) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_staff.hbx_staff_role.permission.can_create_benefit_application).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_create_benefit_application
          end

          it 'returns false' do
            expect(hbx_staff.hbx_staff_role.permission.can_create_benefit_application).to be false
          end
        end
      end

      context "of a developer" do
        let(:developer) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "developer", permission_id: Permission.developer.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(developer.hbx_staff_role.permission.can_create_benefit_application).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_create_benefit_application
          end

          it 'returns false' do
            expect(developer.hbx_staff_role.permission.can_create_benefit_application).to be false
          end
        end
      end
    end

    describe 'update permissions for super admin role to be able to modify benefit application from employers index' do
      let(:given_task_name) {':hbx_admin_can_modify_plan_year'}

      before do
        User.all.delete
        Person.all.delete
      end

      context "of an hbx super admin" do
        let(:hbx_super_admin) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "super_admin", permission_id: Permission.super_admin.id)
          end
        end

        before do
          subject.hbx_admin_can_modify_plan_year
        end

        it 'returns true' do
          expect(hbx_super_admin.hbx_staff_role.permission.can_modify_plan_year).to be true
        end
      end

      context "of an hbx staff" do
        let(:hbx_staff) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_staff.hbx_staff_role.permission.can_modify_plan_year).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_modify_plan_year
          end

          it 'returns false' do
            expect(hbx_staff.hbx_staff_role.permission.can_modify_plan_year).to be false
          end
        end
      end

      context "of an hbx read only" do
        let(:hbx_read_only) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_read_only.hbx_staff_role.permission.can_modify_plan_year).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_modify_plan_year
          end

          it 'returns false' do
            expect(hbx_read_only.hbx_staff_role.permission.can_modify_plan_year).to be false
          end
        end
      end

      context "of an hbx csr supervisor" do
        let(:hbx_csr_supervisor) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_supervisor.hbx_staff_role.permission.can_modify_plan_year).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_modify_plan_year
          end

          it 'returns false' do
            expect(hbx_csr_supervisor.hbx_staff_role.permission.can_modify_plan_year).to be false
          end
        end
      end

      context "of an hbx csr tier1" do
        let(:hbx_csr_tier1) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_tier1.hbx_staff_role.permission.can_modify_plan_year).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_modify_plan_year
          end

          it 'returns false' do
            expect(hbx_csr_tier1.hbx_staff_role.permission.can_modify_plan_year).to be false
          end
        end
      end

      context "of an hbx csr tier2" do
        let(:hbx_csr_tier2) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_tier2.hbx_staff_role.permission.can_modify_plan_year).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_modify_plan_year
          end

          it 'returns false' do
            expect(hbx_csr_tier2.hbx_staff_role.permission.can_modify_plan_year).to be false
          end
        end
      end

      context "of an hbx tier3" do
        let(:hbx_tier3) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
          end
        end

        before do
          subject.hbx_admin_can_modify_plan_year
        end

        it 'returns true' do
          expect(hbx_tier3.hbx_staff_role.permission.can_modify_plan_year).to be true
        end
      end

      context "of a developer" do
        let(:developer) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "developer", permission_id: Permission.developer.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(developer.hbx_staff_role.permission.can_modify_plan_year).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_modify_plan_year
          end

          it 'returns false' do
            expect(developer.hbx_staff_role.permission.can_modify_plan_year).to be false
          end
        end
      end
    end

    describe 'permissions for hbx admin to manage SEP types', :dbclean => :after_each do
      let(:given_task_name) {':hbx_admin_can_manage_qles'}

      before do
        User.all.delete
        Person.all.delete
        Permission.super_admin.update_attributes(can_manage_qles: false)
        Permission.hbx_tier3.update_attributes(can_manage_qles: false)
      end

      context "of an hbx super admin" do
        let!(:hbx_super_admin) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "super_admin", permission_id: Permission.super_admin.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_super_admin.hbx_staff_role.permission.can_manage_qles).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_manage_qles
          end

          it 'returns true' do
            expect(hbx_super_admin.hbx_staff_role.permission.can_manage_qles).to be true
          end
        end
      end

      context "of an hbx staff" do
        let(:hbx_staff) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_staff.hbx_staff_role.permission.can_manage_qles).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_manage_qles
          end

          it 'returns false' do
            expect(hbx_staff.hbx_staff_role.permission.can_manage_qles).to be false
          end
        end
      end

      context "of an hbx read only" do
        let(:hbx_read_only) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_read_only", permission_id: Permission.hbx_read_only.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_read_only.hbx_staff_role.permission.can_manage_qles).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_manage_qles
          end

          it 'returns false' do
            expect(hbx_read_only.hbx_staff_role.permission.can_manage_qles).to be false
          end
        end
      end

      context "of an hbx csr supervisor" do
        let(:hbx_csr_supervisor) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_supervisor", permission_id: Permission.hbx_csr_supervisor.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_supervisor.hbx_staff_role.permission.can_manage_qles).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_manage_qles
          end

          it 'returns false' do
            expect(hbx_csr_supervisor.hbx_staff_role.permission.can_manage_qles).to be false
          end
        end
      end

      context "of an hbx csr tier1" do
        let(:hbx_csr_tier1) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_tier1", permission_id: Permission.hbx_csr_tier1.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_tier1.hbx_staff_role.permission.can_manage_qles).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_manage_qles
          end

          it 'returns false' do
            expect(hbx_csr_tier1.hbx_staff_role.permission.can_manage_qles).to be false
          end
        end
      end

      context "of an hbx csr tier2" do
        let(:hbx_csr_tier2) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_csr_tier2", permission_id: Permission.hbx_csr_tier2.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_csr_tier2.hbx_staff_role.permission.can_manage_qles).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_manage_qles
          end

          it 'returns false' do
            expect(hbx_csr_tier2.hbx_staff_role.permission.can_manage_qles).to be false
          end
        end
      end

      context "of an hbx tier3" do
        let(:hbx_tier3) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_tier3.hbx_staff_role.permission.can_manage_qles).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_manage_qles
          end

          it 'returns true' do
            expect(hbx_tier3.hbx_staff_role.permission.can_manage_qles).to be true
          end
        end
      end

      context "of an hbx staff" do
        let(:hbx_staff) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: Permission.hbx_staff.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(hbx_staff.hbx_staff_role.permission.can_manage_qles).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_manage_qles
          end

          it 'returns false' do
            expect(hbx_staff.hbx_staff_role.permission.can_manage_qles).to be false
          end
        end
      end

      context "of a developer" do
        let(:developer) do
          FactoryBot.create(:person).tap do |person|
            FactoryBot.create(:hbx_staff_role, person: person, subrole: "developer", permission_id: Permission.developer.id)
          end
        end

        it 'returns false before the rake task is ran' do
          expect(developer.hbx_staff_role.permission.can_manage_qles).to be false
        end

        context 'after the rake task is run' do
          before do
            subject.hbx_admin_can_manage_qles
          end

          it 'returns false' do
            expect(developer.hbx_staff_role.permission.can_manage_qles).to be false
          end
        end
      end
    end
  end

  describe 'update permissions for hbx staff role' do
    let(:given_task_name) { "hbx_admin_csr_view_personal_info_page" }

    describe "given a task name" do
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end

    before do
      User.all.delete
      Person.all.delete
      @hbx_staff_person = FactoryBot.create(:person)
      @hbx_csr_supervisor_person = FactoryBot.create(:person)
      @hbx_csr_tier1_person = FactoryBot.create(:person)
      @hbx_csr_tier2_person = FactoryBot.create(:person)
      @super_admin = FactoryBot.create(:person)
      @hbx_tier3 = FactoryBot.create(:person)
      permission_hbx_staff = FactoryBot.create(:permission, :hbx_staff)
      permission_hbx_csr_supervisor = FactoryBot.create(:permission, :hbx_csr_supervisor)
      permission_hbx_csr_tier2 = FactoryBot.create(:permission, :hbx_csr_tier2)
      permission_hbx_csr_tier1 = FactoryBot.create(:permission, :hbx_csr_tier1)
      FactoryBot.create(:permission, :hbx_tier3)
      FactoryBot.create(:permission, :super_admin)
      FactoryBot.create(:hbx_staff_role, person: @hbx_staff_person, subrole: "hbx_staff", permission_id: permission_hbx_staff.id)
      FactoryBot.create(:hbx_staff_role, person: @hbx_csr_supervisor_person, subrole: "hbx_csr_supervisor", permission_id: permission_hbx_csr_supervisor.id)
      FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier2_person, subrole: "hbx_csr_tier1", permission_id: permission_hbx_csr_tier2.id)
      FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier1_person, subrole: "hbx_csr_tier2", permission_id: permission_hbx_csr_tier1.id)
      FactoryBot.create(:hbx_staff_role, person: @super_admin, subrole: "super_admin", permission_id: Permission.super_admin.id)
      FactoryBot.create(:hbx_staff_role, person: @hbx_tier3, subrole: "hbx_tier3", permission_id: Permission.hbx_tier3.id)
      subject.hbx_admin_csr_view_personal_info_page
    end
    it "updates hbx_admin_csr_view_personal_info_page to true" do
      expect(Person.all.to_a.count).to eq(6)
      expect(@hbx_staff_person.hbx_staff_role.permission.view_personal_info_page).to be true
      expect(@super_admin.hbx_staff_role.permission.view_personal_info_page).to be true
      expect(@hbx_tier3.hbx_staff_role.permission.view_personal_info_page).to be true
      expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.view_personal_info_page).to be true
      expect(@hbx_csr_tier2_person.hbx_staff_role.permission.view_personal_info_page).to be true
      expect(@hbx_csr_tier1_person.hbx_staff_role.permission.view_personal_info_page).to be true
    end
  end

  describe 'update permissions for hbx staff role' do
    let(:given_task_name) { "hbx_admin_access_new_consumer_application_sub_tab" }
    let(:given_task_name) { "hbx_admin_access_outstanding_verification_sub_tab" }
    let(:given_task_name) { "hbx_admin_access_identity_verification_sub_tab" }
    let(:given_task_name) { "hbx_admin_can_complete_resident_application" }
    let(:given_task_name) { "hbx_admin_can_access_accept_reject_identity_documents" }
    let(:given_task_name) { "hbx_admin_can_access_accept_reject_paper_application_documents" }
    let(:given_task_name) { "hbx_admin_can_delete_identity_application_documents" }

    describe "given a task name" do
      it "has the given task name" do
        expect(subject.name).to eql given_task_name
      end
    end

    before do
      User.all.delete
      Person.all.delete
      @super_admin = FactoryBot.create(:person)
      @hbx_staff_person = FactoryBot.create(:person)
      @hbx_read_only_person = FactoryBot.create(:person)
      @hbx_csr_supervisor_person = FactoryBot.create(:person)
      @hbx_csr_tier1_person = FactoryBot.create(:person)
      @hbx_csr_tier2_person = FactoryBot.create(:person)
      @hbx_csr_tier3_person = FactoryBot.create(:person)
      permission_hbx_staff = FactoryBot.create(:permission, :hbx_staff)
      permission_super_admin = FactoryBot.create(:permission, :super_admin)
      permission_hbx_read_only = FactoryBot.create(:permission, :hbx_read_only)
      permission_hbx_csr_supervisor = FactoryBot.create(:permission, :hbx_csr_supervisor)
      permission_hbx_csr_tier3 = FactoryBot.create(:permission, :hbx_tier3)
      permission_hbx_csr_tier2 = FactoryBot.create(:permission, :hbx_csr_tier2)
      permission_hbx_csr_tier1 = FactoryBot.create(:permission, :hbx_csr_tier1)
      hbx_staff_role = FactoryBot.create(:hbx_staff_role, person: @hbx_staff_person, subrole: "hbx_staff", permission_id: permission_hbx_staff.id)
      hbx_read_only = FactoryBot.create(:hbx_staff_role, person: @hbx_read_only_person, subrole: "hbx_read_only", permission_id: permission_hbx_staff.id)
      hbx_csr_supervisor_role = FactoryBot.create(:hbx_staff_role, person: @hbx_csr_supervisor_person, subrole: "hbx_csr_supervisor", permission_id: permission_hbx_csr_supervisor.id)
      hbx_csr_tier1_role = FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier2_person, subrole: "hbx_csr_tier1", permission_id: permission_hbx_csr_tier2.id)
      hbx_csr_tier2_role = FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier1_person, subrole: "hbx_csr_tier2", permission_id: permission_hbx_csr_tier1.id)
      FactoryBot.create(:hbx_staff_role, person: @hbx_csr_tier3_person, subrole: "hbx_tier3", permission_id: permission_hbx_csr_tier3.id)
      FactoryBot.create(:hbx_staff_role, person: @super_admin, subrole: "super_admin", permission_id: permission_super_admin.id)
    end
    it "updates hbx_admin_can_access_new_consumer_application_sub_tab to true" do
      subject.hbx_admin_can_access_new_consumer_application_sub_tab
      expect(Person.all.to_a.count).to eq(7)
      expect(@hbx_staff_person.hbx_staff_role.permission.can_access_new_consumer_application_sub_tab).to be true
      expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_access_new_consumer_application_sub_tab).to be true
      expect(@hbx_csr_tier2_person.hbx_staff_role.permission.can_access_new_consumer_application_sub_tab).to be true
      expect(@hbx_csr_tier1_person.hbx_staff_role.permission.can_access_new_consumer_application_sub_tab).to be true
    end

    it "updates hbx_admin_can_access_identity_verification_sub_tab to true" do
      subject.hbx_admin_can_access_identity_verification_sub_tab
      expect(Person.all.to_a.count).to eq(7)
      expect(@hbx_staff_person.hbx_staff_role.permission.can_access_identity_verification_sub_tab).to be true
      expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_access_identity_verification_sub_tab).to be true
      expect(@hbx_csr_tier1_person.hbx_staff_role.permission.can_access_identity_verification_sub_tab).to be true
      expect(@hbx_csr_tier2_person.hbx_staff_role.permission.can_access_identity_verification_sub_tab).to be true
    end
    it "updates hbx_admin_can_access_outstanding_verification_sub_tab to true" do
      subject.hbx_admin_can_access_outstanding_verification_sub_tab
      expect(Person.all.to_a.count).to eq(7)
      expect(@hbx_staff_person.hbx_staff_role.permission.can_access_outstanding_verification_sub_tab).to be true
    end
    it "updates hbx_admin_can_complete_resident_application to true" do
      subject.hbx_admin_can_complete_resident_application
      expect(Person.all.to_a.count).to eq(7)
      expect(@hbx_staff_person.hbx_staff_role.permission.can_complete_resident_application).to be true
      expect(@super_admin.hbx_staff_role.permission.can_complete_resident_application).to be true
      expect(@hbx_csr_tier3_person.hbx_staff_role.permission.can_complete_resident_application).to be true
    end
    it "updates hbx_admin_can_access_accept_reject_identity_documents to true" do
      subject.hbx_admin_can_access_accept_reject_identity_documents
      expect(Person.all.to_a.count).to eq(7)
      expect(@hbx_staff_person.hbx_staff_role.permission.can_access_accept_reject_identity_documents).to be true
    end
    it "updates hbx_admin_can_access_accept_reject_paper_application_documents to true" do
      subject.hbx_admin_can_access_accept_reject_paper_application_documents
      expect(Person.all.to_a.count).to eq(7)
      expect(@hbx_staff_person.hbx_staff_role.permission.can_access_accept_reject_paper_application_documents).to be true
      expect(@hbx_csr_supervisor_person.hbx_staff_role.permission.can_access_accept_reject_paper_application_documents).to be true
      expect(@hbx_csr_tier1_person.hbx_staff_role.permission.can_access_accept_reject_paper_application_documents).to be true
      expect(@hbx_csr_tier2_person.hbx_staff_role.permission.can_access_accept_reject_paper_application_documents).to be true
    end
    it "updates hbx_admin_can_delete_identity_application_documents to true" do
      subject.hbx_admin_can_delete_identity_application_documents
      expect(Person.all.to_a.count).to eq(7)
      expect(@hbx_staff_person.hbx_staff_role.permission.can_delete_identity_application_documents).to be true
    end
  end

  describe 'build test roles' do
    let(:given_task_name) {':build_test_roles'}
    before do
      User.all.delete
      Person.all.delete
      allow(Permission).to receive_message_chain('hbx_staff.id'){FactoryBot.create(:permission, :hbx_staff).id}
      allow(Permission).to receive_message_chain('hbx_read_only.id'){FactoryBot.create(:permission, :hbx_read_only).id}
      allow(Permission).to receive_message_chain('hbx_csr_supervisor.id'){FactoryBot.create(:permission, :hbx_csr_supervisor).id}
      allow(Permission).to receive_message_chain('hbx_csr_tier2.id'){FactoryBot.create(:permission,  :hbx_csr_tier2).id}
      allow(Permission).to receive_message_chain('hbx_csr_tier1.id'){FactoryBot.create(:permission,  :hbx_csr_tier1).id}
      allow(Permission).to receive_message_chain('developer.id'){FactoryBot.create(:permission,  :developer).id}
      allow(Permission).to receive_message_chain('hbx_tier3.id'){FactoryBot.create(:permission,  :hbx_tier3).id}
      allow(Permission).to receive_message_chain('super_admin.id'){FactoryBot.create(:permission,  :super_admin).id}
      subject.build_test_roles
    end
    it "creates permissions" do
      expect(User.all.to_a.count).to eq(8)
      expect(Person.all.to_a.count).to eq(8)
      expect(Person.all.to_a.map{|p| p.hbx_staff_role.subrole}).to match_array roles
    end
  end
end