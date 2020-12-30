require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_family_member_to_coverage_household")

describe AddFamilyMemberToCoverageHousehold, dbclean: :after_each do

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  let(:given_task_name) { "add_family_member_to_coverage_household" }
  subject { AddFamilyMemberToCoverageHousehold.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "add family member to coverage household", dbclean: :after_each do
    let!(:person) { FactoryBot.create(:person) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    before do
      @dependent = FactoryBot.create(:person)
      @dep_member = FactoryBot.create(:family_member, family: family, person: @dependent)
      person.person_relationships << PersonRelationship.new(relative_id: @dependent.id, kind: 'child')
      person.save!
    end

    let(:fm_env_support) {{primary_hbx_id: person.hbx_id, dependent_hbx_id: @dependent.hbx_id}}

    context 'active family member' do
      it 'should add coverage household member to immediate family coverage household' do
        with_modified_env fm_env_support do
          expect(family.active_household.coverage_households.first.coverage_household_members.count).to eq 1
          subject.migrate
          family.reload
          family.active_household.reload
          expect(family.active_household.coverage_households.first.coverage_household_members.count).to eq 2
        end
      end
    end

    context 'inactive family member' do
      before do
        @dep_member.update_attributes!(is_active: false)
        @dep_member.save!
      end

      it 'should not add coverage household member to immediate family coverage household' do
        with_modified_env fm_env_support do
          expect(family.active_household.coverage_households.first.coverage_household_members.count).to eq 1
          subject.migrate
          family.reload
          family.active_household.reload
          expect(family.active_household.coverage_households.first.coverage_household_members.count).to eq 1
        end
      end
    end
  end
end
