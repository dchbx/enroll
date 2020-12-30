# frozen_string_literal: true

require 'rails_helper'
require 'factory_bot_rails'

describe QualifyingLifeEventKindPolicy, dbclean: :after_each do
  context '.can_manage_qles?' do
    let!(:super_admin_permission) { FactoryBot.create(:permission, :super_admin) }
    let!(:hbx_tier3_permission)   { FactoryBot.create(:permission, :hbx_tier3) }
    let!(:developer_permission)   { FactoryBot.create(:permission, :developer) }
    let!(:hbx_csr_tier1_permission)   { FactoryBot.create(:permission, :hbx_csr_tier1) }
    let!(:hbx_csr_tier2_permission)   { FactoryBot.create(:permission, :hbx_csr_tier2) }
    let!(:hbx_csr_supervisor_permission)   { FactoryBot.create(:permission, :hbx_csr_supervisor) }
    let!(:hbx_read_only_permission)   { FactoryBot.create(:permission, :hbx_read_only) }
    let!(:hbx_staff_permission)   { FactoryBot.create(:permission, :hbx_staff) }

    let!(:user)                   { FactoryBot.create(:user) }
    let!(:person)                 { FactoryBot.create(:person, :with_hbx_staff_role, user: user) }
    subject                       { QualifyingLifeEventKindPolicy.new(user, nil) }

    it 'should return true for hbx_tier3 role' do
      person.hbx_staff_role.update_attributes!(permission_id: hbx_tier3_permission.id)
      expect(subject.can_manage_qles?).to eq true
    end

    it 'should return true for super admin role' do
      person.hbx_staff_role.update_attributes!(permission_id: super_admin_permission.id)
      expect(subject.can_manage_qles?).to eq true
    end

    it 'should return true for developer role' do
      person.hbx_staff_role.update_attributes!(permission_id: developer_permission.id)
      expect(subject.can_manage_qles?).to eq false
    end

    it 'should return true for hbx_csr_tier1 role' do
      person.hbx_staff_role.update_attributes!(permission_id: hbx_csr_tier1_permission.id)
      expect(subject.can_manage_qles?).to eq false
    end

    it 'should return true for hbx_csr_tier2 role' do
      person.hbx_staff_role.update_attributes!(permission_id: hbx_csr_tier2_permission.id)
      expect(subject.can_manage_qles?).to eq false
    end

    it 'should return true for hbx_csr_supervisor role' do
      person.hbx_staff_role.update_attributes!(permission_id: hbx_csr_supervisor_permission.id)
      expect(subject.can_manage_qles?).to eq false
    end

    it 'should return true for hbx_read_only role' do
      person.hbx_staff_role.update_attributes!(permission_id: hbx_read_only_permission.id)
      expect(subject.can_manage_qles?).to eq false
    end

    it 'should return true for hbx_staff role' do
      person.hbx_staff_role.update_attributes!(permission_id: hbx_staff_permission.id)
      expect(subject.can_manage_qles?).to eq false
    end
  end
end
