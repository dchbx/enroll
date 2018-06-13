module Config::SiteConcern
  def site_short_name
    Settings.site.short_name
  end

  def site_uses_default_devise_path?
    Settings.site.use_default_devise_path
  end

  def site_create_routes
    Settings.site.create_routes
  end

  def site_sign_in_routes
    Settings.site.sign_in_routes
  end

  def site_redirect_on_timeout_route
    Settings.site.curam_enabled? ? SamlInformation.iam_login_url : new_user_session_path
  end
end
