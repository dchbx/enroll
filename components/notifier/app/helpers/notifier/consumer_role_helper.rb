# frozen_string_literal: true

module Notifier
  module ConsumerRoleHelper
    def dependent_hash(dependent, member)
      MergeDataModels::Dependent.new({first_name: dependent.first_name,
                                      last_name: dependent.last_name,
                                      age: dependent.age,
                                      federal_tax_filing_status: filer_type(member['filer_type']),
                                      expected_income_for_coverage_year: member['actual_income'].present? ? ActionController::Base.helpers.number_to_currency(member['actual_income'], :precision => 0) : "",
                                      citizenship: citizen_status(member["citizen_status"]),
                                      dc_resident: member['resident'].capitalize,
                                      tax_household_size: member['tax_hh_count'],
                                      incarcerated: member['incarcerated'] == 'N' ? 'No' : 'Yes',
                                      other_coverage: member["mec"].presence || 'No',
                                      aptc: member['aptc'],
                                      aqhp_eligible: dependent.is_aqhp_eligible,
                                      uqhp_eligible: dependent.is_uqhp_eligible,
                                      totally_ineligible: dependent.is_totally_ineligible})
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

    def format_date(date)
      return '' if date.blank?

      date.strftime('%B %d, %Y')
    end
  end
end