module BenefitSponsors
  module RegistrationHelper

    def is_broker_profile?(profile_type)
      profile_type == "broker_agency"
    end

    def is_sponsor_profile?(profile_type)
      profile_type == "benefit_sponsor"
    end

    def is_general_agency_profile?(profile_type)
      profile_type == "general_agency"
    end

    def l10n(translation_key, interpolated_keys={})
      begin
        I18n.t(translation_key, interpolated_keys.merge(raise: true)).html_safe
      rescue I18n::MissingTranslationData
        translation_key.gsub(/\W+/, '').titleize
      end
    end
  end
end
