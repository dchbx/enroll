# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'add_sbc_role_to_person')

describe AddSbcRoleToPerson, dbclean: :after_each do

  let(:given_task_name) { 'add_sbc_role_to_person' }
  subject { AddSbcRoleToPerson.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe '#sbc_role' do
    let(:person) { FactoryBot.create(:person) }
    let!(:super_admin) { create(:permission, :super_admin) }

    it 'should create an sbc role for a person' do
      ClimateControl.modify hbx_id: person.hbx_id do
        subject.migrate
        person.reload
        expect(person.sbc_role).to be_present
      end
    end
  end
end
