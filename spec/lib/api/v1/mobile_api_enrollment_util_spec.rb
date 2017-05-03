require "rails_helper"
require 'lib/api/v1/support/mobile_employer_data'

RSpec.describe Api::V1::Mobile::EnrollmentUtil, dbclean: :after_each do
  include_context 'employer_data'

  context 'Enrollments' do

    it 'should return active employer sponsored health enrollments' do
      enrollment = Api::V1::Mobile::EnrollmentUtil.new
      hbx_enrollment1 = HbxEnrollment.new kind: 'employer_sponsored', coverage_kind: 'health', is_active: true, submitted_at: Time.now
      hbx_enrollment2 = HbxEnrollment.new kind: 'employer_sponsored', coverage_kind: 'health', is_active: true
      hbx_enrollments = [hbx_enrollment1, hbx_enrollment2]

      enrollment.instance_variable_set(:@all_enrollments, hbx_enrollments)
      hes = enrollment.send(:active_employer_sponsored_health_enrollments)
      expect(hes).to be_a_kind_of Array
      expect(hes.size).to eq 1
      expect(hes.pop).to be_a_kind_of HbxEnrollment
    end

    it 'should return employee enrollments' do
      assignments = [benefit_group_assignment, benefit_group_assignment]
      grouped_bga_enrollments = [hbx_enrollment].group_by { |x| x.benefit_group_assignment_id.to_s }
      enrollments = Api::V1::Mobile::EnrollmentUtil.new(assignments: assignments, grouped_bga_enrollments: grouped_bga_enrollments).employee_enrollments
      expect(enrollments).to be_a_kind_of Array
      expect(enrollments.size).to eq 2

      active = enrollments[0]
      renewal = enrollments[1]
      expect(active).to include('health', 'dental', :start_on)
      expect(renewal).to include('health', 'dental', :start_on)

      active_health, renewal_health = active['health'], renewal['health']
      active_dental, renewal_dental = active['dental'], renewal['dental']
      expect(active_health).to include(:status, :employer_contribution, :employee_cost,
                                       :total_premium, :plan_name, :plan_type, :metal_level,
                                       :benefit_group_name)
      expect(renewal_health).to include(:status, :employer_contribution, :employee_cost,
                                        :total_premium, :plan_name, :plan_type, :metal_level,
                                        :benefit_group_name)
      expect(active_dental).to include(:status)
      expect(renewal_dental).to include(:status)
      expect(active_health[:status]).to eq 'Enrolled'
      expect(renewal_health[:status]).to eq 'Enrolled'
      expect(active_dental[:status]).to eq 'Not Enrolled'
      expect(renewal_dental[:status]).to eq 'Not Enrolled'
    end

    it 'should return benefit group assignments' do
      enrollment = Api::V1::Mobile::EnrollmentUtil.new
      enrollment.instance_variable_set(:@all_enrollments, [shop_enrollment_barista])
      bgas = enrollment.send(:bg_assignment_ids, HbxEnrollment::ENROLLED_STATUSES)
      expect(bgas).to be_a_kind_of Array
      expect(bgas.size).to eq 1
      expect(bgas.pop).to be_a_kind_of BSON::ObjectId

      expect { enrollment.benefit_group_assignment_ids(HbxEnrollment::ENROLLED_STATUSES, [], []) }.to raise_error(LocalJumpError)
      enrollment.benefit_group_assignment_ids HbxEnrollment::ENROLLED_STATUSES, [], [] do |enrolled_ids, waived_ids, terminated_ids|
        expect(enrolled_ids).to be_a_kind_of Array
        expect(enrolled_ids.size).to eq 1
        expect(enrolled_ids.pop).to be_a_kind_of BSON::ObjectId
      end
    end

    it 'should initialize enrollments' do
      enrollment = Api::V1::Mobile::EnrollmentUtil.new
      enrollments = enrollment.send(:initialize_enrollment, [hbx_enrollment], 'health')
      expect(enrollments).to be_a_kind_of Array
      expect(enrollments.shift).to be_a_kind_of HbxEnrollment
      expect(enrollments.shift).to include(:status, :employer_contribution, :employee_cost, :total_premium, :plan_name,
                                           :plan_type, :metal_level, :benefit_group_name)
      enrollments = enrollment.send(:initialize_enrollment, [hbx_enrollment], 'dental')
      expect(enrollments).to be_a_kind_of Array
      expect(enrollments.pop).to include(:status)
    end

    it 'should return the status label for enrollment status' do
      enrollment = Api::V1::Mobile::EnrollmentUtil.new
      expect(enrollment.send(:status_label_for, 'coverage_terminated')).to eq 'Terminated'
      expect(enrollment.send(:status_label_for, 'auto_renewing')).to eq 'Enrolled'
      expect(enrollment.send(:status_label_for, 'inactive')).to eq 'Waived'
      expect(enrollment.send(:status_label_for, 'coverage_selected')).to eq 'Enrolled'
    end

  end

end