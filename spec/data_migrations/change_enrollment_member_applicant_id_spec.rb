require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'change_enrollment_member_applicant_id')

describe ChangeEnrollmentMemberApplicantId, dbclean: :after_each do
  let(:given_task_name) { 'change_enrollment_member_applicant_id' }
  subject { ChangeEnrollmentMemberApplicantId.new(given_task_name, double(:current_scope => nil)) }
  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end
  
  describe 'do not change enrollment member if no enrollment_member was found', dbclean: :after_each do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
    let(:family_member){FactoryBot.create(:family_member,family:family)}
    let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment,terminated_on:Date.today,household: family.active_household, family: family)}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member,hbx_enrollment:hbx_enrollment,applicant_id: family.family_members.first.id,is_subscriber: true, eligibility_date:Date.today )}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member,hbx_enrollment:hbx_enrollment,applicant_id: family.family_members.last.id,is_subscriber: false, eligibility_date:Date.today )}

    it 'should not change enrollment member applicant id if no enrollment found' do
      with_modified_env  enrollment_hbx_id:hbx_enrollment.hbx_id,enrollment_member_id: '',family_member_id:family_member.id do 
        applicant_id = hbx_enrollment_member1.applicant_id
        expect(hbx_enrollment_member1.applicant_id).to eq applicant_id
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment_member1.applicant_id).to eq applicant_id
      end
    end

    it 'should not change enrollment member applicant id if no enrollment found' do
      with_modified_env  enrollment_hbx_id:'' , enrollment_member_id:  hbx_enrollment_member1.id,family_member_id:family_member.id do 
        applicant_id = hbx_enrollment_member1.applicant_id
        expect(hbx_enrollment_member1.applicant_id).to eq applicant_id
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment_member1.applicant_id).to eq applicant_id
      end
    end

    it 'should not change enrollment member applicant id if no enrollment found' do
      with_modified_env  enrollment_hbx_id:  hbx_enrollment.hbx_id , enrollment_member_id:  hbx_enrollment_member1.id,family_member_id:'' do 
        applicant_id = hbx_enrollment_member1.applicant_id
        expect(hbx_enrollment_member1.applicant_id).to eq applicant_id
        subject.migrate
        hbx_enrollment.reload
        expect(hbx_enrollment_member1.applicant_id).to eq applicant_id
      end
    end

    it 'should change enrollment member applicant id if all information is provided' do
      with_modified_env  enrollment_hbx_id:  hbx_enrollment.hbx_id , enrollment_member_id:  hbx_enrollment_member1.id,family_member_id: family_member.id do 
        applicant_id = hbx_enrollment_member1.applicant_id
        new_applicant_id = family_member.id
        expect(hbx_enrollment_member1.applicant_id).to eq applicant_id
        subject.migrate
        hbx_enrollment.reload
        hbx_enrollment_member1.reload
        expect(hbx_enrollment_member1.applicant_id).to eq new_applicant_id
      end
    end

    def with_modified_env(options, &block)
      ClimateControl.modify(options, &block)
    end
  end
end

