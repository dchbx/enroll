# frozen_string_literal: true

module L10nHelper
  def l10n(translation_key, interpolated_keys = {})
    Rails.logger.error {"#L10nHelper passed non string key: #{translation_key.inspect}"} unless translation_key.is_a?(String)
    return "Translation Missing" unless translation_key.is_a?(String)
    t(translation_key, interpolated_keys.merge(default: translation_key.gsub(/\W+/, '').titleize)).html_safe
  end
end
