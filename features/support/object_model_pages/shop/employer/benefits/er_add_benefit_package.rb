# frozen_string_literal: true

#benefit_sponsors/benefit_sponsorships/5ff77ba896a4a17b76f892bb/benefit_applications/new
class EmployerAddBenefitPackage

  def self.select_start_on_dropdown
    'div[class="selectric-wrapper selectric-floatlabel selectric-benefit-application-start-date selectric-below"] span'
  end

  def self.end_on
    'input[id="benefit_application_end_on"]'
  end

  def self.open_enrollment_start_date
    'benefit_application[open_enrollment_start_on]'
  end

  def self.open_enrollment_end_date
    'OPEN ENROLLMENT END DATE'
  end

  def self.full_time_employees
    'benefit_application[fte_count]'
  end

  def self.part_time_employees
    'benefit_application[pte_count]'
  end

  def self.medicare_second_payers
    'benefit_application[msp_count]'
  end

  def self.continue_btn
    'input[id="benefitContinueBtn"]'
  end
end