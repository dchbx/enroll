# frozen_string_literal: true

module GlossaryHelper
  def support_texts
    @support_texts ||= YAML.load_file("app/views/shared/support_text_household.yml")
  end
end
