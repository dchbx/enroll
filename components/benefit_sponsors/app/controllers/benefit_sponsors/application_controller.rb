module BenefitSponsors
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :set_last_portal_visited
    include Pundit

    helper BenefitSponsors::Engine.helpers

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    def self.current_site
      site_key = Settings.site.key
      case site_key
      when :cca
        BenefitSponsors::Site.by_site_key(:cca).first
      when :dc
        BenefitSponsors::Site.by_site_key(:dc).first
      end
    end

    protected

    def set_current_person(required: true)
      if current_user.try(:person).try(:agent?) && session[:person_id].present?
        @person = Person.find(session[:person_id])
      else
        @person = current_user.person
      end
      redirect_to logout_saml_index_path if required && !set_current_person_succeeded?
    end

    def set_current_person_succeeded?
      return true if @person
      message = {}
      message[:message] = 'Application Exception - person required'
      message[:session_person_id] = session[:person_id]
      message[:user_id] = current_user.id
      message[:oim_id] = current_user.oim_id
      message[:url] = request.original_url
      log(message, :severity=>'error')
      return false
    end

    def set_flash_by_announcement
      return if current_user.blank?
      if flash.blank? || flash[:warning].blank?
        announcements = if current_user.has_hbx_staff_role?
                          Announcement.get_announcements_by_portal(request.path, @person)
                        else
                          current_user.get_announcements_by_roles_and_portal(request.path)
                        end
        dismiss_announcements = JSON.parse(session[:dismiss_announcements] || "[]") rescue []
        announcements -= dismiss_announcements
        flash.now[:warning] = announcements
      end
    end

    def cur_page_no(alph="a")
      page_string = params.permit(:page)[:page]
      page_string.blank? ? alph : page_string.to_s
    end

    def page_alphabets(source, field)
      # A good optimization would be an aggregate
      # source.collection.aggregate([{ "$group" => { "_id" => { "$substr" => [{ "$toUpper" => "$#{field}"},0,1]}}}, "$sort" =>{"_id"=>1} ]).map do
      #   |object| object["_id"]
      # end
      # but source.collection acts on the entire collection (Model.all) hence cant be used here as source is a Mongoid::Criteria
    source.distinct(field).collect {|word| word.first.upcase}.uniq.sort
    rescue
      ("A".."Z").to_a
    end

    def create_sso_account(user, personish, timeout, account_role = "individual")
      if !user.idp_verified?
        IdpAccountManager.create_account(user.email, user.oim_id, stashed_user_password, personish, account_role, timeout)
        session[:person_id] = personish.id
        session.delete("stashed_password")
        user.switch_to_idp!
      end
      #TODO TREY KEVIN JIM CSR HAS NO SSO_ACCOUNT
      session[:person_id] = personish.id if user.person && user.person.agent?
      yield
    end

    def stashed_user_password
      session["stashed_password"]
    end

    def set_last_portal_visited
      if controller_name == "broker_agency_profiles" && action_name == "show"
        return if (current_user.blank? || (current_user.person.present? && !current_user.person.broker_role.present?) ||current_user.last_portal_visited == request.referrer)
        current_user.update_attributes(last_portal_visited: request.referrer)
      end
    end

    private

    def user_not_authorized(exception)
      policy_name = exception.policy.class.to_s.underscore

      flash[:error] = "Access not allowed for #{exception.query}, (Pundit policy)"
      respond_to do |format|
        format.json { render nothing: true, status: :forbidden }
        format.html { redirect_to(session[:custom_url] || request.referrer || main_app.root_path)}
        format.js   { render nothing: true, status: :forbidden }
      end
    end
  end
end
