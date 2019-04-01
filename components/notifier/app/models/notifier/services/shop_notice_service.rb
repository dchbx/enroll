module Notifier
  module Services
    class ShopNoticeService

      def recipients
        {
          "Employer" => "Notifier::MergeDataModels::EmployerProfile",
          "Employee" => "Notifier::MergeDataModels::EmployeeProfile",
          "Broker" => "Notifier::MergeDataModels::BrokerProfile",
          "Broker Agency" => "Notifier::MergeDataModels::BrokerAgencyProfile",
          "GeneralAgency" => "Notifier::MergeDataModels::GeneralAgency"
        }
      end

      def setting_placeholders
        system_settings.inject([]) do |placeholders, (category, attribute_set)|
          attribute_set.each do |attribute|
            placeholders << {
              title: "#{category.to_s.humanize}: #{attribute.humanize}",
              target: ["Settings", category, attribute].join('.')
            }
          end
          placeholders
        end
      end

      def system_settings
        {
          :site => %w(domain_name home_url help_url faqs_url main_web_address short_name byline long_name shop_find_your_doctor_url document_verification_checklist_url registration_path),
          :contact_center => %w(name alt_name phone_number fax tty_number alt_phone_number email_address small_business_email appeals),
          :'contact_center.mailing_address' => %w(name address_1 address_2 city state zip_code),
          :aca => %w(state_name state_abbreviation),
          :'aca.shop_market' => %w(valid_employer_attestation_documents_url binder_payment_due_on),
        }
      end
    end
  end
end