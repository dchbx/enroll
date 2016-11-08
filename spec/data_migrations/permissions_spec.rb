require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "define_permissions")

describe DefinePermissions do
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