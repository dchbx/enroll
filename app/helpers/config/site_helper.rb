module Config::SiteHelper

  def site_redirect_on_timeout_route
    Settings.site.curam_enabled? ? SamlInformation.iam_login_url : new_user_session_path
  end

  def site_byline
    Settings.site.byline
  end

  def site_domain_name
    Settings.site.domain_name
  end

  def site_website_name
    Settings.site.website_name
  end

  def site_privacy_policy
    Settings.site.privacy_policy
  end

  def site_website_link
    link_to site_website_name, site_website_name
  end

  def site_find_expert_link
    link_to site_find_expert_url, site_find_expert_url
  end

  def site_find_expert_url
    site_home_url + "/find-expert"
  end

  def site_home_business_url
    Settings.site.home_business_url
  end

  def site_home_url
    Settings.site.home_url
  end

  def site_curam_enabled?
    Settings.site.curam_enabled
  end

  def site_brokers_agreement_path
    link_to "#{Settings.aca.state_name} #{Settings.site.short_name} Broker Agreement", Settings.site.terms_and_conditions_url
  end

  def site_home_link
    link_to site_home_url, site_home_url
  end

  def site_help_url
    Settings.site.help_url
  end

  def site_business_resource_center_url
    Settings.site.business_resource_center_url
  end

  def link_to_site_business_resource_center
    link_to "Business Resource Center", site_business_resource_center_url
  end

  def site_nondiscrimination_notice_url
    Settings.site.nondiscrimination_notice_url
  end

  def site_policies_url
    Settings.site.policies_url
  end

  def site_faqs_url
    Settings.site.faqs_url
  end

  def site_short_name
    Settings.site.short_name
  end

  def site_registration_path(resource_name, params)
    if Settings.site.registration_path.present? && ENV['AWS_ENV'] == 'prod'
       Settings.site.registration_path
    else
      new_registration_path(resource_name, :invitation_id => params[:invitation_id])
    end
  end

  def site_long_name
    Settings.site.long_name
  end

  def site_broker_quoting_enabled?
    Settings.site.broker_quoting_enabled
  end

  def site_main_web_address
    Settings.site.main_web_address
  end

  def site_main_web_address_url
    Settings.site.main_web_address_url
  end

  def site_main_web_link
    link_to site_website_name, site_main_web_address_url
  end

  def site_make_their_premium_payments_online
    Settings.site.make_their_premium_payments_online
  end

  def link_to_make_their_premium_payments_online
    link_to "make your premium payments online", site_make_their_premium_payments_online
  end

  def health_care_website
      Settings.site.health_care_website
  end

  def health_care_website_url
      Settings.site.health_care_website_url
  end

  def ivl_login_url
    Settings.site.ivl_login_url
  end

  def site_uses_default_devise_path?
    Settings.site.use_default_devise_path
  end

  def find_your_doctor_url
    Settings.site.shop_find_your_doctor_url
  end

  def site_main_web_address_text
    Settings.site.main_web_address_text
  end

  def site_website_address
    link_to site_website_name, site_main_web_address_url
  end

  def non_discrimination_notice_url
    link_to site_nondiscrimination_notice_url, site_nondiscrimination_notice_url
  end

  def mail_non_discrimination_email
    mail_to non_discrimination_email, non_discrimination_email
  end

  def site_employer_application_deadline_link
    Settings.site.employer_application_deadline_link
  end


  def site_guidance_for_business_owners_url
    Settings.site.guidance_for_business_owners_url
  end

  def site_non_discrimination_complaint_url
    link_to non_discrimination_complaint_url, non_discrimination_complaint_url
  end

  def site_document_verification_checklist_url
    Settings.site.document_verification_checklist_url
  end

  def site_invoice_bill_url
    Settings.site.invoice_bill_url
  end

  def mail_address
    Settings.site.mail_address
  end
end
