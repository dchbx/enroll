module BenefitSponsors
  module ApplicationHelper

    def bootstrap_class_for flash_type
      case flash_type
        when "notice"
          "alert-info"
        when "success"
          "alert-success"
        when "error"
          "alert-danger"
        when "alert"
          "alert-warning"
      end
    end

    def flash_messages(opts = {})
      flash.each do |msg_type, message|
        concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} alert-dismissible fade show") do
          concat content_tag(:button, 'x', class: "close", data: { dismiss: 'alert' })
          concat message
        end)
      end
      nil
    end

    def format_date(date_value)
      date_value.strftime("%m/%d/%Y") if date_value.respond_to?(:strftime)
    end

    def menu_tab_class(a_tab, current_tab)
      (a_tab == current_tab) ? raw(" class=\"active\"") : ""
    end

    def get_benefit_sponsors_header_text(controller_name)
      benefit_sponsors_portal_display_name(controller_name)
    end

    def user_first_name_last_name_and_suffix
      if signed_in?
        current_user.person.try(:first_name_last_name_and_suffix) ? current_user.person.first_name_last_name_and_suffix : (current_user.oim_id).downcase
      end
    end

    def copyright_notice
      raw("<span class='copyright'><i class='fa fa-copyright fa-lg' aria-hidden='true'></i> #{Settings.site.copyright_period_start}-#{TimeKeeper.date_of_record.year} #{Settings.site.short_name}. All Rights Reserved.</span>")
    end

    def render_flash
      rendered = []
      flash.each do |type, messages|
        if messages.respond_to?(:each)
          messages.each do |m|
            rendered << render(:partial => 'layouts/flash', :locals => {:type => type, :message => m}) unless m.blank?
          end
        else
          rendered << render(:partial => 'layouts/flash', :locals => {:type => type, :message => messages}) unless messages.blank?
        end
      end
      rendered.join('').html_safe
    end

    def retrieve_show(provider, message)
      inboxes_message_path(provider, message_id: message.id)
    end

    def plan_shop_tool_tip_helper
      "Employers offering coverage through #{site_short_name} for the first time must have an open enrollment period of no less than 14 days. Employers renewing their #{site_short_name} coverage must have an open enrollment period of at least 30 days."
    end

    def find_and_sort_inbox_messages(provider, folder)
      provider.inbox.messages.select {|m| folder == (m.folder.try(:capitalize) || 'Inbox')}.sort_by(&:created_at).reverse
    end

    def benefit_application_claim_quote_warnings(benefit_applications)
      benefit_application = benefit_applications.where(aasm_state: :draft).first
      return [], "#claimBenefitApplicationQuoteModal" unless benefit_application

      if benefit_application.is_renewing?
        return ["<p>Claiming this quote will replace your existing renewal draft plan year. This action cannot be undone. Are you sure you wish to claim this quote?</p><p>If you wish to review the quote details prior to claiming, please contact your Broker to provide you with a pdf copy of this quote.</p>"], "#claimQuoteWarning"
      else
        return ["<p>Claiming this quote will replace your existing draft plan year. This action cannot be undone. Are you sure you wish to claim this quote?</p><p>If you wish to review the quote details prior to claiming, please contact your Broker to provide you with a pdf copy of this quote.</p>"], "#claimQuoteWarning"
      end
    end

    def retrieve_inbox(provider, folder: 'inbox')
      broker_agency_mailbox = inbox_profiles_broker_agencies_broker_agency_profile_path(id: provider.id.to_s, folder: folder)
      return broker_agency_mailbox if provider.try(:broker_role)
      case (provider.model_name.name.split('::').last)
        when "AcaShopDcEmployerProfile"
          inbox_profiles_employers_employer_profile_path(id: provider.id.to_s, folder: folder)
        when "HbxProfile"
          #TODO fix it for HBX profile
        when "BrokerAgencyProfile"
          inbox_profiles_broker_agencies_broker_agency_profile_path(id: provider.id.to_s, folder: folder)
        when "GeneralAgencyProfile"
          #TODO FIX IT for GA
      end
    end

    def benefit_sponsor_display_families_tab(user,profile_id)
      if user.present?
        user.has_broker_agency_staff_role? || user.has_general_agency_staff_role? || user.is_benefit_sponsor_active_broker?(profile_id)
      end
    end

    def total_active_census_employees(profile_id)
      employer_profile = BenefitSponsors::Organizations::Profile.find(profile_id)
      employer_profile.census_employees.active.count
    end

    def total_messages(record_id)
      profile = BenefitSponsors::Organizations::Profile.find(record_id)

      if profile.primary_broker_role.present?
        person = profile.primary_broker_role.person
        person.inbox.unread_messages.count
      else
        return 0
      end
    end

    def format_name(first_name: nil, last_name: nil, middle_name: nil, name_sfx: nil)
      given_name = [first_name, middle_name].reject(&:nil? || empty?).join(' ')
      sir_name  = content_tag(:strong, mixed_case(last_name))
      raw([mixed_case(given_name), sir_name, name_sfx].reject(&:nil? || empty?).join(' '))
    end
  end
end
