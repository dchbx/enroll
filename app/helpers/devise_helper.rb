# frozen_string_literal: true

module DeviseHelper
  def devise_error_messages!
    return "" if resource.errors.empty?

    resource.errors.messages[:username] = resource.errors.messages.delete(:oim_id) if resource.errors.messages.keys.include?(:oim_id)

    messages = resource.errors.messages.map do |_key, value|
      value.map { |v| content_tag(:li, v) }
    end.join
    html = <<-HTML
    <div class="alert alert-error module registration-rules" role="alert">
      <div class="text-center">
        <strong>
         #{l10n('devise.errors.message')}
        </strong>
      </div>
      <br/>
      <ul>#{messages}</ul>
    </div>
    HTML

    html.html_safe
  end
end
