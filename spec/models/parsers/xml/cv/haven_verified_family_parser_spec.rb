require 'rails_helper'

describe "HavenVerifiedFamilyParser" do
  let(:class_name) {self.name.demodulize}
  include_examples "haven parser examples", class_name

  context "verified members" do
    it 'should get family members' do
      expect(subject.family_members.class).to eq Array
    end

    it 'should get households' do
      expect(subject.households.class).to eq Array
    end

    it 'should get households' do
      expect(subject.integrated_case_id).to eq integrated_case_id.text.strip
    end

    it 'should get broker_accounts' do
      expect(subject.broker_accounts.class).to eq Array
    end

    it 'should get fin_app_id' do
      expect(subject.fin_app_id).to eq fin_app_id.text.strip
    end

    it 'should get haven_ic_id' do
      expect(subject.haven_ic_id).to eq haven_ic_id.text.strip
    end

    it 'should get haven_app_id' do
      expect(subject.haven_app_id).to eq haven_app_id.text.strip
    end

    it 'should get e_case_id' do
      expect(subject.e_case_id).to eq e_case_id.text.strip
    end

    it 'should get primary_family_member_id' do
      expect(subject.primary_family_member_id).to eq primary_family_member_id.text.strip
    end
  end
end
