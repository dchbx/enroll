# frozen_string_literal: true

#Dependent service for UQHPAQHP of Projected Renewal Eligibility Notice

class Notifier::Services::DependentService

  include Notifier::ConsumerRoleHelper

  def initialize(is_uqhp_notice, member, renewing_enrollments)
    @is_uqhp_notice = is_uqhp_notice
    @payload_member = member
    @person = person_details
    @first_name = f_name
    @last_name = l_name
    @age = calculate_age
    @is_totally_ineligible = totally_ineligible?
    @is_uqhp_eligible = uqhp_eligible?
    @is_aqhp_eligible = aqhp_eligible?
    @is_magi_medicaid_eligibile = medicaid_eligible?
    @is_enrolled = is_enrolled?(renewing_enrollments)
  end

  attr_accessor :is_uqhp_notice, :payload_member, :age, :is_aqhp_eligible, :is_magi_medicaid_eligibile
  attr_accessor :person, :is_totally_ineligible, :is_uqhp_eligible
  attr_accessor :first_name, :last_name

  private

  def person_details
    Person.by_hbx_id(payload_member['person_hbx_id']).first
  end

  def f_name
    is_uqhp_notice ? person.first_name : payload_member['first_name']
  end

  def l_name
    is_uqhp_notice ? person.last_name : payload_member['last_name']
  end

  def calculate_age
    if is_uqhp_notice
      person.age_on(TimeKeeper.date_of_record).presence || nil
    else
      age_of_aqhp_person(TimeKeeper.date_of_record, Date.strptime(payload_member['dob'], '%m/%d/%Y'))
    end
  end

  def aqhp_eligible?
    is_uqhp_notice ? false : payload_member['aqhp_eligible'].casecmp('YES').zero?
  end

  def totally_ineligible?
    is_uqhp_notice ? false : payload_member['totally_inelig'].casecmp('YES').zero?
  end

  def uqhp_eligible?
    is_uqhp_notice.presence || payload_member['uqhp_eligible'].casecmp('YES').zero?
  end

  def medicaid_eligible?
    is_uqhp_notice.presence || payload_member['magi_medicaid'].casecmp('YES').zero?
  end

  def is_enrolled?(renewing_enrollments)
    return nil unless renewing_enrollments.present?

    renewing_enrollments.any? do |enrollment|
      enrollment.hbx_enrollment_members.detect { |hbx_enrollment_member| hbx_enrollment_member.hbx_id == payload_member['person_hbx_id']}
    end
  end
end
