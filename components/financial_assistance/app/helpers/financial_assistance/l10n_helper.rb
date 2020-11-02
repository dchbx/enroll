# frozen_string_literal: true

module FinancialAssistance
  module L10nHelper
    def l10n(translation_key, interpolated_keys = {})
      t(translation_key, interpolated_keys.merge(raise: true))
    rescue I18n::MissingTranslationData
      translation_key.gsub(/\W+/, '').titleize
    end
  end
end
