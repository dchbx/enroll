require "rails_helper"

RSpec.describe Api::V1::Mobile::Employee, dbclean: :after_each do

  context 'Enrollments' do

    it 'should return active employer sponsored health enrollments' do

      enrollment = Api::V1::Mobile::Enrollment.new
      hbx_enrollment1 = HbxEnrollment.new kind: 'employer_sponsored', coverage_kind: 'health', is_active: true, submitted_at: Time.now
      hbx_enrollment2 = HbxEnrollment.new kind: 'employer_sponsored', coverage_kind: 'health', is_active: true
      hbx_enrollments = [hbx_enrollment1, hbx_enrollment2]

      enrollment.instance_variable_set(:@all_enrollments, hbx_enrollments)
      active_employer_sponsored_health_enrollments = enrollment.send(:active_employer_sponsored_health_enrollments)

    end

  end

end