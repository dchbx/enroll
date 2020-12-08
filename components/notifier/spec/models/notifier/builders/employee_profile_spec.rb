# frozen_string_literal: true

# Date.today converted to TimeKeeper.date_of_record

RSpec.describe Notifier::Builders::EmployeeProfile, dbclean: :around_each do
  let(:employee_profile) { ::Notifier::Builders::EmployeeProfile.new }
  let(:payload) do
    { 'notice_params' => { 'qle_title' => 'test test', 'qle_event_on' => (TimeKeeper.date_of_record + 1.day).to_s} }
  end
  let(:sep) { double('SpecialEnrollmentPeriod', title: 'sep_title') }

  before :each do
    allow(employee_profile).to receive('special_enrollment_period').and_return(sep)
    employee_profile.payload = payload
  end

  context 'special_enrollment_period_event_on' do
    it 'should return qle event_on date that is sent in the payload' do
      expect(employee_profile.special_enrollment_period_event_on).to eq((TimeKeeper.date_of_record + 1.day).to_s)
    end

    it 'should not raise error when there is an existing sep' do
      expect{employee_profile.special_enrollment_period_event_on}.not_to raise_error
    end
  end

  context 'special_enrollment_period_title' do
    it 'should return qle title that is sent in the payload' do
      expect(employee_profile.special_enrollment_period_title).to eq('test test')
    end

    it 'should not return title of an existing sep' do
      expect(employee_profile.special_enrollment_period_title).not_to eq('sep_title')
    end
  end
end
