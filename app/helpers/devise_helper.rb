module DeviseHelper
  def devise_error_messages!
    return "" if resource.errors.empty?

    resource.errors.messages[:username] = resource.errors.messages.delete :oim_id

    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    sentence = I18n.t("errors.messages.not_saved",
                      count: resource.errors.count,
                      resource: resource.class.model_name.human.downcase)

    html = <<-HTML
    <div class="alert alert-error module registration-rules" role="alert">
      <div class="text-center">
        <strong>
          Password Requirements
        </strong>
      </div>
      <br/>
      <strong>#{sentence}</strong>
      <ul>#{messages}</ul>
    </div>
    HTML

    html.html_safe
  end
end
