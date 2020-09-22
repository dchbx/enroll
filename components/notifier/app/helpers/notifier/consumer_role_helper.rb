# frozen_string_literal: true

module Notifier
  module ConsumerRoleHelper
    def dependent_hash(dependent, member)
      MergeDataModels::Dependent.new(
        {
          first_name: dependent.first_name,
          last_name: dependent.last_name,
          age: dependent.age,
          federal_tax_filing_status: filer_type(member['filer_type']),
          expected_income_for_coverage_year: format_currency(member['actual_income']),
          citizenship: citizen_status(member["citizen_status"]),
          dc_resident: member['resident'].capitalize,
          tax_household_size: member['tax_hh_count'],
          incarcerated: member['incarcerated'] == 'N' ? 'No' : 'Yes',
          other_coverage: member["mec"].presence || 'No',
          reasons_for_ineligibility: reasons_for_ineligibility(member),
          is_enrolled: dependent.is_enrolled,
          mec: check_format(member['mec']),
          aptc: member['aptc'],
          indian_conflict: check_format(member['indian']),
          is_medicaid_chip_eligible: check_format(member['magi_medicaid']),
          is_non_magi_medicaid_eligible: check_format(member['non_magi_medicaid']),
          magi_medicaid_monthly_income_limit: format_currency(member['medicaid_monthly_income_limit']),
          magi_as_percentage_of_fpl: member['magi_as_fpl'],
          has_access_to_affordable_coverage: check_format(member['mec']),
          no_medicaid_because_of_income: member["nonmedi_reason"].present? && member["nonmedi_reason"].downcase == "over income" ? true : false,
          no_medicaid_because_of_immigration: member["nonmedi_reason"].present? && member["nonmedi_reason"].downcase == "immigration" ? true : false,
          no_medicaid_because_of_age: member["nonmedi_reason"].present? && member["nonmedi_reason"].downcase == "age" ? true : false,
          no_aptc_because_of_income: member["nonaptc_reason"].present? && member["nonaptc_reason"].downcase == "over income" ? true : false,
          no_aptc_because_of_tax: member["nonaptc_reason"].present? && member["nonaptc_reason"].downcase == "tax" ? true : false,
          no_aptc_because_of_mec: member["nonaptc_reason"].present? && member["nonaptc_reason"].downcase == "medicare eligible" ? true : false,
          no_csr_because_of_income: member["noncsr_reason"].present? && member["noncsr_reason"].downcase == "over income" ? true : false,
          no_csr_because_of_tax: member["noncsr_reason"].present? && member["noncsr_reason"].downcase == "tax" ? true : false,
          no_csr_because_of_mec: member["noncsr_reason"].present? && member["noncsr_reason"].downcase == "medicare eligible" ? true : false,
          non_applicant: member["nonaptc_reason"].present? && member["nonaptc_reason"].downcase == "non-applicant" ? true : false,
          aqhp_eligible: dependent.is_aqhp_eligible,
          uqhp_eligible: dependent.is_uqhp_eligible,
          totally_ineligible: dependent.is_totally_ineligible
        }
      )
    end

    def reasons_for_ineligibility(member)
      reason_for_ineligibility = []
      reason_for_ineligibility << "this person isn’t a resident of the District of Columbia. Go to healthcare.gov to learn how to apply for coverage in the right state." if member['dc_resident']&.capitalize == 'NO'
      reason_for_ineligibility << "this person is currently serving time in jail or prison for a criminal conviction." unless member['incarcerated'] == 'N'
      if lawful_presence_outstanding?(member)
        reason_for_ineligibility << "this person doesn’t have an eligible immigration status,
                                  but may be eligible for a local medical assistance program
                                  called the DC Health Care Alliance. For more information, please
                                  contact #{Settings.site.short_name} at 1234567890."
      end
      reason_for_ineligibility
    end

    # TODO: Fix this method
    def lawful_presence_outstanding?(_member)
      false
    end

    def member_hash(fam_member)
      MergeDataModels::Dependent.new({first_name: fam_member.first_name,
                                      last_name: fam_member.last_name,
                                      age: fam_member.age})
    end

    def address_hash(mailing_address)
      MergeDataModels::Address.new({street_1: mailing_address.address_1,
                                    street_2: mailing_address.address_2,
                                    city: mailing_address.city,
                                    state: mailing_address.state,
                                    zip: mailing_address.zip})
    end

    def ivl_oe_start_date_value
      Settings.aca.individual_market.upcoming_open_enrollment.start_on.strftime('%B %d, %Y')
    end

    def ivl_oe_end_date_value
      Settings.aca
              .individual_market
              .upcoming_open_enrollment
              .end_on.strftime('%B %d, %Y')
    end

    def expected_income_for_coverage_year_value(payload)
      if payload['notice_params']['primary_member']['actual_income'].present?
        ActionController::Base.helpers.number_to_currency(
          payload['notice_params']['primary_member']['actual_income'],
          :precision => 0
        )
      else
        ""
      end
    end

    def tax_households_hash(tax_hh)
      MergeDataModels::TaxHousehold.new(
        {
          csr_percent_as_integer: tax_hh.csr_percent_as_integer,
          max_aptc: tax_hh.max_aptc,
          aptc_csr_annual_household_income: tax_hh.aptc_csr_annual_household_income,
          aptc_csr_monthly_household_income: tax_hh.aptc_csr_monthly_household_income,
          aptc_annual_income_limit: tax_hh.aptc_annual_income_limit,
          csr_annual_income_limit: tax_hh.csr_annual_income_limit,
          applied_aptc: tax_hh.applied_aptc
        }
      )
    end

    def phone_number(legal_name)
      case legal_name
      when "BestLife"
        "(800) 433-0088"
      when "CareFirst"
        "(855) 444-3119"
      when "Delta Dental"
        "(800) 471-0236"
      when "Dominion"
        "(855) 224-3016"
      when "Kaiser"
        "(844) 524-7370"
      end
    end

    def filer_type(type)
      case type
      when "Filers"
        "Tax Filer"
      when "Dependents"
        "Tax Dependent"
      when "Married Filing Jointly"
        "Married Filing Jointly"
      when "Married Filing Separately"
        "Married Filing Separately"
      else
        ""
      end
    end

    def age_of_aqhp_person(date, dob)
      age = date.year - dob.year
      if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
        age - 1
      else
        age
      end
    end

    def format_currency(value, precision = 0)
      return '' if value.blank?

      ActionController::Base.helpers.number_to_currency(value, :precision => precision)
    end

    def format_date(date)
      return '' if date.blank?

      date.strftime('%B %d, %Y')
    end

    def check_format(value)
      value.try(:upcase) == "YES"
    end
  end
end