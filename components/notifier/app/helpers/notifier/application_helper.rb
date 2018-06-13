module Notifier
  module ApplicationHelper
    def portal_display_name(controller)
      if current_user.nil?
        "<a class='portal'>#{Settings.site.header_message}</a>".html_safe
      elsif current_user.try(:has_hbx_staff_role?)
        link_to "#{image_tag 'icons/icon-exchange-admin.png'} &nbsp; I'm an Admin".html_safe, main_app.exchanges_hbx_profiles_root_path, class: "portal"
      elsif current_user.person.try(:broker_role)
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Broker".html_safe, broker_agencies_profile_path(id: current_user.person.broker_role.broker_agency_profile_id), class: "portal"
      elsif current_user.try(:person).try(:csr_role) || current_user.try(:person).try(:assister_role)
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Trained Expert".html_safe, home_exchanges_agents_path, class: "portal"
      elsif current_user.person && current_user.person.active_employee_roles.any?
        link_to "#{image_tag 'icons/icon-individual.png'} &nbsp; I'm an #{controller=='employer_profiles'? 'Employer': 'Employee'}".html_safe, family_account_path, class: "portal"
      elsif (controller_path.include?("insured") && current_user.try(:has_consumer_role?))
        if current_user.identity_verified_date.present?
          link_to "#{image_tag 'icons/icon-family.png'} &nbsp; Individual and Family".html_safe, family_account_path, class: "portal"
        else
          "<a class='portal'>#{image_tag 'icons/icon-family.png'} &nbsp; Individual and Family</a>".html_safe
        end
      elsif current_user.try(:has_broker_agency_staff_role?)
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Broker".html_safe, broker_agencies_profile_path(id: current_user.person.broker_role.broker_agency_profile_id), class: "portal"
      elsif current_user.try(:has_employer_staff_role?)
        link_to "#{image_tag 'icons/icon-business-owner.png'} &nbsp; I'm an Employer".html_safe, employers_employer_profile_path(id: current_user.person.active_employer_staff_roles.first.employer_profile_id), class: "portal"
      elsif current_user.has_general_agency_staff_role?
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a General Agency".html_safe, general_agencies_root_path, class: "portal"
      else
        "<a class='portal'>#{Settings.site.header_message}</a>".html_safe
      end
    end

    def get_header_text(controller_name)
      portal_display_name(controller_name)
    end

    def site_main_web_address_business
      Settings.site.main_web_address_business
    end

    def site_faqs_url
      Settings.site.faqs_url
    end

    def dc_exchange?
      Settings.aca.state_abbreviation.upcase == 'DC'
    end

    def site_short_name
      Settings.site.short_name
    end

    #TODO: Add a similar notice attachment setting for DC
    def shop_non_discrimination_attachment
      Settings.notices.shop.attachments.non_discrimination_attachment
    end

    #TODO: Add a similar notice attachment setting for DC
    def shop_envelope_without_address
      Settings.notices.shop.attachments.envelope_without_address
    end
  end
end
