module Notifier
  module Builders
    class FaaApplication
      # Builder class FaaApplication for  IVL_ERA Eligibility Notice

      include ActionView::Helpers::NumberHelper
      include Notifier::ApplicationHelper
      include Config::ContactCenterHelper
      include Config::SiteHelper

      attr_accessor :faa_application, :merge_model, :full_name, :payload,
                    :event_name, :sep_id

      def initialize
        data_object = Notifier::MergeDataModels::FaaApplication.new
        data_object.mailing_address = Notifier::MergeDataModels::Address.new
        @merge_model = data_object
      end

      def resource=(resource)
        @faa_application = resource
      end

      def notice_date
        merge_model.notice_date = TimeKeeper.date_of_record
                                            .strftime('%B %d, %Y')
      end

      def application_date
        merge_model.application_date = faa_application.submitted_at.strftime('%B %d, %Y')
      end

      def date_of_letter_45_days
        merge_model.date_of_letter_45_days = (TimeKeeper.date_of_record + 45.days).strftime('%B %d, %Y')
      end

      def date_of_letter_95_days
        merge_model.date_of_letter_95_days = (TimeKeeper.date_of_record + 95.days).strftime('%B %d, %Y')
      end

      def first_name
        merge_model.first_name = person.first_name
      end

      def last_name
        merge_model.last_name = person.last_name
      end

      def primary_fullname
        merge_model.primary_fullname = person.full_name.titleize
      end

      def age
        merge_model.age = person.age_on(TimeKeeper.date_of_record)
      end

      def effective_date
        merge_model.effective_date = faa_application.effective_date.strftime('%B %d, %Y')
      end

      def max_aptc
        ## Needs verification from business
        merge_model.max_aptc = ""
      end

      def coverage_year
        merge_model.coverage_year = TimeKeeper.date_of_record.next_year.year
      end

      def coverage_year_oe_start_date
        merge_model.coverage_year_oe_start_date = Settings.aca
                                                .individual_market
                                                .upcoming_open_enrollment
                                                .start_on.strftime('%B %d, %Y')
      end

      def coverage_year_oe_end_date
        merge_model.coverage_year_oe_end_date = Settings.aca
                                              .individual_market
                                              .upcoming_open_enrollment
                                              .end_on.strftime('%B %d, %Y')
      end

      def monthly_household_income
        merge_model.monthly_household_income = primary_applicant.magi_medicaid_monthly_household_income
      end

      def annual_household_income
        merge_model.annual_household_income = ""
      end

      def aptc_annual_income_limit
        merge_model.aptc_annual_income_limit = ""
      end

      def csr_annual_income_limit
        merge_model.csr_annual_income_limit = ""
      end

      def csr_annual_allowable_limit
        merge_model.csr_annual_allowable_limit = ""
      end

      def format_date(date)
        return '' if date.blank?
        date.strftime('%B %d, %Y')
      end

      def primary_applicant
        faa_application.primary_applicant
      end

      def person
        primary_applicant.person
      end

      def append_contact_details
        mailing_address = person.mailing_address
        return if mailing_address.blank?

        merge_model.mailing_address = MergeDataModels::Address.new(
          {
            street_1: mailing_address.address_1,
            street_2: mailing_address.address_2,
            city: mailing_address.city,
            state: mailing_address.state,
            zip: mailing_address.zip
          }
        )
      end

#       def dependents
#         payload['notice_params']['dependents'].each do |member|
#           dependent = Notifier::Services::DependentService.new(uqhp_notice?, member)
#           merge_model.dependents << MergeDataModels::Dependent.new(
#             {
#               first_name: dependent.first_name,
#               last_name: dependent.last_name,
#               age: dependent.age,
#               federal_tax_filing_status: filer_type(member['filer_type']),
#               expected_income_for_coverage_year: member['actual_income'].present? ? ActionController::Base.helpers.number_to_currency(member['actual_income'], :precision => 0) : "",
#               citizenship: citizen_status(member["citizen_status"]),
#               dc_resident: member['resident'],
#               tax_household_size: member['tax_hh_count'],
#               incarcerated: member['incarcerated'] == 'N' ? 'No' : 'Yes',
#               other_coverage: member["mec"].presence || 'No',
#               aptc: member['aptc'],
#               aqhp_eligible: dependent.is_aqhp_eligible,
#               uqhp_eligible: dependent.is_uqhp_eligible,
#               totally_ineligible: dependent.is_totally_ineligible
#             }
#           )
#         end
#       end

#       # def previous_coverage_year
#       #   merge_model.previous_coverage_year = coverage_year.to_i - 1
#       # end

#       # def dc_resident
#       #   merge_model.dc_resident =
#       #     payload['notice_params']['primary_member']['resident'].capitalize
#       # end

#       # def expected_income_for_coverage_year
#       #   merge_model.expected_income_for_coverage_year =
#       #     if payload['notice_params']['primary_member']['actual_income'].present?
#       #       ActionController::Base.helpers.number_to_currency(
#       #         payload['notice_params']['primary_member']['actual_income'],
#       #         :precision => 0
#       #       )
#       #     else
#       #       ""
#       #     end
#       # end

#       # def federal_tax_filing_status
#       #   merge_model.federal_tax_filing_status = filer_type(payload['notice_params']['primary_member']['filer_type'])
#       # end

#       # def citizenship
#       #   merge_model.citizenship = citizen_status(payload['notice_params']['primary_member']['citizen_status'])
#       # end

#       # def tax_household_size
#       #   merge_model.tax_household_size = payload['notice_params']['primary_member']['tax_hh_count'].to_i
#       # end

#       # def actual_income
#       #   merge_model.actual_income = payload['notice_params']['primary_member']['actual_income'].to_i
#       # end

#       # def aqhp_eligible
#       #   merge_model.aqhp_eligible =
#       #     if uqhp_notice?
#       #       false
#       #     else
#       #       payload['notice_params']['primary_member']['aqhp_eligible'].casecmp('YES').zero?
#       #     end
#       # end

#       # def totally_ineligible
#       #   merge_model.totally_ineligible =
#       #     if uqhp_notice?
#       #       false
#       #     else
#       #       payload['notice_params']['primary_member']['totally_inelig'].casecmp('YES').zero?
#       #     end
#       # end

#       # def uqhp_eligible
#       #   merge_model.uqhp_eligible =
#       #     if uqhp_notice?
#       #       true
#       #     else
#       #       false
#       #     end
#       # end

#       # def incarcerated
#       #   merge_model.incarcerated = payload['notice_params']['primary_member']['incarcerated'] == 'N' ? 'No' : 'Yes'
#       # end

#       # def irs_consent
#       #   merge_model.irs_consent =
#       #     if uqhp_notice?
#       #       false
#       #     else
#       #       payload['notice_params']['primary_member']['irs_consent'].casecmp('YES').zero?
#       #     end
#       # end

#       # def magi_medicaid
#       #   merge_model.magi_medicaid =
#       #     if uqhp_notice?
#       #       false
#       #     else
#       #       payload['notice_params']['primary_member']['magi_medicaid'].casecmp('YES').zero?
#       #     end
#       # end

#       # def non_magi_medicaid
#       #   merge_model.non_magi_medicaid =
#       #     if uqhp_notice?
#       #       true
#       #     else
#       #       payload['notice_params']['primary_member']['non_magi_medicaid'].casecmp('YES').zero?
#       #     end
#       # end

#       # def csr
#       #   merge_model.csr = payload['notice_params']['primary_member']['csr'].casecmp('YES').zero?
#       # end

#       # def csr_percent
#       #   merge_model.csr_percent = payload['notice_params']['primary_member']['csr_percent'].blank? ? nil : Integer(payload['notice_params']['primary_member']['csr_percent'])
#       # end

#       def depents
#         true
#       end

#       def aqhp_eligible?
#         aqhp_eligible
#       end

#       def totally_ineligible?
#         totally_ineligible
#       end

#       def uqhp_eligible?
#         uqhp_eligible
#       end

#       def incarcerated?
#         incarcerated.casecmp('NO').zero?
#       end

#       def irs_consent?
#         irs_consent
#       end

#       def magi_medicaid?
#         magi_medicaid
#       end

#       def non_magi_medicaid?
#         non_magi_medicaid
#       end

#       def aptc_is_zero?
#         aptc.present? && aptc.to_i.zero?
#       end

#       def aqhp_or_non_magi_medicaid?
#         aqhp_eligible? || non_magi_medicaid?
#       end

#       def uqhp_or_non_magi_medicaid?
#         uqhp_eligible? || non_magi_medicaid?
#       end

#       def irs_consent_not_needed?
#         !irs_consent
#       end

#       def aptc_amount_available?
#         aptc.present?
#       end

#       def csr?
#         return false if uqhp_notice?
#         csr
#       end

#       def aqhp_eligible_and_irs_consent_not_needed?
#         return false if uqhp_notice?
#         aqhp_eligible? && !irs_consent?
#       end

#       def csr_is_73?
#         false unless csr?
#         csr_percent == 73
#       end

#       def csr_is_87?
#         false unless csr?
#         csr_percent == 87
#       end

#       def csr_is_94?
#         false unless csr?
#         csr_percent == 94
#       end

#       def csr_is_100?
#         false unless csr?
#         csr_percent == 100
#       end

#       def csr_is_zero?
#         false unless csr?
#         csr_percent.zero?
#       end

#       def csr_is_nil?
#         csr_percent.nil?
#       end

#       def uqhp_notice?
#         event_name == 'projected_eligibility_notice_1'
#       end

#       # def filer_type(type)
#       #   case type
#       #   when "Filers"
#       #     "Tax Filer"
#       #   when "Dependents"
#       #     "Tax Dependent"
#       #   when "Married Filing Jointly"
#       #     "Married Filing Jointly"
#       #   else
#       #     ""
#       #   end
#       # end

#       # def citizen_status(status)
#       #   if uqhp_notice?
#       #     uqhp_citizen_status(status)
#       #   else
#       #     aqhp_citizen_status(status)
#       #   end
#       # end

#       # def aqhp_citizen_status(status)
#       #   case status
#       #   when "US"
#       #     "US Citizen"
#       #   when "LP"
#       #     "Lawfully Present"
#       #   when "NC"
#       #     "US Citizen"
#       #   else
#       #     ""
#       #   end
#       # end

#       # def uqhp_citizen_status(status)
#       #   case status
#       #   when "us_citizen"
#       #     "US Citizen"
#       #   when "alien_lawfully_present"
#       #     "Lawfully Present"
#       #   when "indian_tribe_member"
#       #     "US Citizen"
#       #   when "lawful_permanent_resident"
#       #     "Lawfully Present"
#       #   when "naturalized_citizen"
#       #     "US Citizen"
#       #   else
#       #     "Ineligible Immigration Status"
#       #   end
#       # end
    end
  end
end
