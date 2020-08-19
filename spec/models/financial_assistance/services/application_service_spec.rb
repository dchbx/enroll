require 'rails_helper'

RSpec.describe 'ApplicationService' do
  include_examples 'submitted application with two active members and one applicant'

  subject do
    FinancialAssistance::Services::ApplicationService.new(family)
  end

  context 'generate_code' do
    it 'should return method code when there is submitted application' do
      expect(subject.generate_code).to eq :copy!
    end
  end

  context 'drafted_app' do
    it 'should not return application' do
      expect(subject.drafted_app.blank?).to eq true
    end
  end

  context 'submitted_app' do
    it 'should return application' do
      expect(subject.submitted_app.blank?).to eq false
    end
  end

  context 'when method name: sync! is send to process_application' do
    before do
      application.update_attributes(aasm_state: 'draft', submitted_at: nil)
      application.reload
    end

    it 'should perform sync_family_members_with_applicants' do
      subject.process_application
      family.reload
      expect(family.applications.count).to eq 1
      expect(family.application_in_progress.applicants.count).to eq 2
    end
  end

  context 'when method name: copy! is send to process_application' do
    it 'should perform copy_application and sync family members' do
      subject.process_application
      family.reload
      expect(family.applications.count).to eq 2
      expect(family.application_in_progress.applicants.count).to eq 2
    end
  end

  context 'when application_id is used to process_application' do
    subject do
      FinancialAssistance::Services::ApplicationService.new(family,{application_id: application.id})
    end

    it 'should perform copy_application and sync family members' do
      subject.process_application
      family.reload
      expect(family.applications.count).to eq 2
      expect(family.application_in_progress.applicants.count).to eq 2
    end
  end
end
