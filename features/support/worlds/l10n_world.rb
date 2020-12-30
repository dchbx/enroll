# frozen_string_literal: true

module L10nWorld
  def l10n(translation_key, interpolated_keys={})
    begin
      I18n.t(translation_key, interpolated_keys.merge(raise: true)).html_safe
    rescue I18n::MissingTranslationData
      translation_key.gsub(/\W+/, '').titleize
    end
  end
end

World(L10nWorld)