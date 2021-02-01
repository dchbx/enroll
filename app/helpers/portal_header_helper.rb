module PortalHeaderHelper
  include L10nHelper
  include ApplicationHelper

  def portal_display_name(controller)
    if current_user.nil?
      "<a class='portal'>#{l10n("welcome.index.welcome_to_site_header")}</a>".html_safe
    elsif current_user.try(:has_hbx_staff_role?)
      link_to "#{image_tag 'icons/icon-exchange-admin.png'} &nbsp; I'm an Admin".html_safe, main_app.exchanges_hbx_profiles_root_path, class: "portal"
    elsif current_user.person.try(:broker_role) && controller_path.exclude?('general_agencies')
      link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Broker".html_safe, get_broker_profile_path, class: "portal"
    elsif current_user.try(:person).try(:csr_role) || current_user.try(:person).try(:assister_role)
      link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Trained Expert".html_safe, main_app.home_exchanges_agents_path, class: "portal"
    elsif current_user.person && current_user.person.active_employee_roles.any?
      if controller_path.include?('broker_agencies')
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Broker".html_safe, get_broker_profile_path, class: "portal"
      elsif controller_path.include?('general_agencies')
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a General Agency".html_safe, benefit_sponsors.profiles_general_agencies_general_agency_profile_path(id: current_user.person.general_agency_staff_roles.first.benefit_sponsors_general_agency_profile_id), class: "portal"
      elsif controller == 'employer_profiles' || controller_path.include?('employers')
        #current user has both broker_agency staff role and employee role but not employer_staff_roles
        if current_user.person.active_employer_staff_roles.present?
          employer_profile_path = benefit_sponsors.profiles_employers_employer_profile_path(id: current_user.person.active_employer_staff_roles.first.benefit_sponsor_employer_profile_id, :tab => 'home')
          link_to "#{image_tag 'icons/icon-business-owner.png'} &nbsp; I'm an Employer".html_safe, employer_profile_path, class: "portal"
        elsif current_user.try(:has_broker_agency_staff_role?)
          link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Broker".html_safe, get_broker_profile_path, class: "portal"
        end
      else
        link_to "#{image_tag exchange_icon_path('icon-individual.png')} &nbsp; I'm an Employee".html_safe, main_app.family_account_path, class: "portal"
      end
    elsif (controller_path.include?("insured") && current_user.try(:has_consumer_role?)) ||
      (EnrollRegistry.feature_enabled?(:financial_assistance) && controller_path.include?("financial_assistance") && current_user.try(:has_consumer_role?))
      if current_user.identity_verified_date.present?
        link_to "#{image_tag 'icons/icon-family.png'} &nbsp; Individual and Family".html_safe, main_app.family_account_path, class: "portal"
      else
        "<a class='portal'>#{image_tag 'icons/icon-family.png'} &nbsp; Individual and Family</a>".html_safe
      end
    elsif current_user.try(:has_broker_agency_staff_role?) && controller_path.exclude?('general_agencies') && controller_path.exclude?('employers')
      link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Broker".html_safe, get_broker_profile_path, class: "portal"
    elsif current_user.try(:has_general_agency_staff_role?)
      if current_user.try(:has_employer_staff_role?) && controller_path.include?('employers')
        link_to "#{image_tag 'icons/icon-business-owner.png'} &nbsp; I'm an Employer".html_safe, benefit_sponsors.profiles_employers_employer_profile_path(id: current_user.person.active_employer_staff_roles.first.benefit_sponsor_employer_profile_id, :tab=>'home'), class: "portal"
      else
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a General Agency".html_safe, benefit_sponsors.profiles_general_agencies_general_agency_profile_path(id: current_user.person.active_general_agency_staff_roles.first.benefit_sponsors_general_agency_profile_id), class: "portal"
      end
    elsif current_user.try(:has_employer_staff_role?)
      link_to "#{image_tag 'icons/icon-business-owner.png'} &nbsp; I'm an Employer".html_safe, benefit_sponsors.profiles_employers_employer_profile_path(id: current_user.person.active_employer_staff_roles.first.benefit_sponsor_employer_profile_id, :tab=>'home'), class: "portal"
    else
      "<a class='portal'>#{l10n("welcome.index.byline", welcome_text: "#{Settings.site.header_message}")}</a>".html_safe
    end
  end

  def get_broker_profile_path
    #if class is from benefit sponsor
    klass_name = @broker_agency_profile.class.to_s.demodulize.constantize
    if @broker_agency_profile.is_a? BrokerAgencyProfile
      main_app.broker_agencies_profile_path(id: @broker_agency_profile.id)
    elsif klass_name == BrokerAgencyProfile
      benefit_sponsors.profiles_broker_agencies_broker_agency_profile_path(id: @broker_agency_profile.id)
    end
  end

  # def enrollment_name
  #   begin
  #     person = Person.find(session[:person_id])
  #     name=  'Assisting: ' + person.full_name
  #   rescue
  #     name = ''
  #   end
  # end
  # def agent_header
  #   header_text = "<div style='display:inline-block'>&nbsp; I'm a Trained Expert</div>"
  #   link_to "#{image_tag 'icons/icon-expert.png'}#{header_text}".html_safe, home_exchanges_agents_path
  # end
  #
  # def hbx_staff_header
  #   header_text = "<div style='display:inline-block; white-space: nowrap; position: relative; top: -5px;'>&nbsp; I'm an Admin</div>"
  #   link_to "#{image_tag 'icons/icon-exchange-admin.png', style: 'position: relative; top: -8px; left: 10px; margin-right: 5px;'} #{header_text}".html_safe, exchanges_hbx_profiles_root_path, style: 'padding: 16px 20px 0 0;'
  # end
  #
  # def broker_header
  #   header_text = "<div style='display:inline-block white-space: nowrap; position: relative; top: -5px;'>&nbsp; I'm a Broker</div>"
  #   link_to "#{image_tag 'icons/icon-expert.png', style: 'position: relative; top: -8px; left: 10px; margin-right: 5px;'} #{header_text}".html_safe, broker_agencies_profile_path(id: current_user.person.broker_role.benefit_sponsors_broker_agency_profile_id), style: 'padding: 16px 20px 0 0;'
  # end
end
