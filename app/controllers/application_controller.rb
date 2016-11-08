class ApplicationController < ActionController::Base
  include Pundit
  include Acapi::Notifiers

  after_action :update_url, :unless => :format_js?

  def format_js?
   request.format.js?
  end

  # force_ssl

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  ## Devise filters
  before_filter :require_login, unless: :authentication_not_required?
  before_filter :authenticate_user_from_token!
  before_filter :authenticate_me!

  # for i18L
  before_action :set_locale

  # for current_user
  before_action :set_current_user

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  rescue_from ActionController::InvalidCrossOriginRequest do |exception|
    error_message = {
      :error => {
        :message => exception.message,
        :inspected => exception.inspect,
        :backtrace => exception.backtrace.join("\n")
      },
      :url => request.original_url,
      :method => request.method,
      :parameters => params.to_s,
      :source => request.env["HTTP_REFERER"]
    }

    log(JSON.dump(error_message), {:severity => 'critical'})
  end

  def access_denied
    render file: 'public/403.html', status: 403
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    flash[:error] = "Access not allowed for #{policy_name}.#{exception.query}, (Pundit policy)"
      respond_to do |format|
      format.json { render nothing: true, status: :forbidden }
      format.html { redirect_to(request.referrer || root_path)}
      format.js   { render nothing: true, status: :forbidden }
    end
  end

  def authenticate_me!
    # Skip auth if you are trying to log in
    return true if ["welcome","saml", "broker_roles", "office_locations", "invitations"].include?(controller_name.downcase)
    authenticate_user!
  end

  def create_sso_account(user, personish, timeout, account_role = "individual")
    if !user.idp_verified?
      IdpAccountManager.create_account(user.email, user.oim_id, stashed_user_password, personish, account_role, timeout)
      session[:person_id] = personish.id
      session.delete("stashed_password")
      user.switch_to_idp!
    end
    #TODO TREY KEVIN JIM CSR HAS NO SSO_ACCOUNT
    session[:person_id] = personish.id if current_user.try(:person).try(:agent?)
    yield
  end

  private
    def secure_message(from_provider, to_provider, subject, body)
      message_params = {
        sender_id: from_provider.id,
        parent_message_id: to_provider.id,
        from: from_provider.legal_name,
        to: to_provider.legal_name,
        subject: subject,
        body: body
      }

      create_secure_message(message_params, to_provider, :inbox)
      create_secure_message(message_params, from_provider, :sent)
    end

    def create_secure_message(message_params, inbox_provider, folder)
      message = Message.new(message_params)
      message.folder =  Message::FOLDER_TYPES[folder]
      msg_box = inbox_provider.inbox
      msg_box.post_message(message)
      msg_box.save
    end

    def set_locale
      requested_locale = params[:locale] || user_preferred_language || extract_locale_from_accept_language_header || I18n.default_locale
      requested_locale = I18n.default_locale unless I18n.available_locales.include? requested_locale.try(:to_sym)
      I18n.locale = requested_locale
    end

    def extract_locale_from_accept_language_header
      if request.env['HTTP_ACCEPT_LANGUAGE']
        request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
      else
        nil
      end
    end

    def update_url
      if (controller_name == "employer_profiles" && action_name == "show") ||
          (controller_name == "families" && action_name == "home") ||
          (controller_name == "profiles" && action_name == "new")
          if current_user.last_portal_visited != request.original_url
            current_user.last_portal_visited = request.original_url
            current_user.save
          end
      end
    end

    def user_preferred_language
      current_user.try(:preferred_language)
    end

  protected
  # Broker Signup form should be accessibile for anonymous users
    def authentication_not_required?
      devise_controller? ||
      (controller_name == "broker_roles") ||
      (controller_name == "office_locations") ||
      (controller_name == "invitations") ||
      (controller_name == "saml")
    end

    def require_login
      unless current_user
        unless request.format.js?
          session[:portal] = url_for(params)
        end
        redirect_to new_user_registration_path
      end
    rescue Exception => e
      message = {}
      message[:message] = "Application Exception - #{e.message}"
      message[:session_person_id] = session[:person_id] if session[:person_id]
      message[:user_id] = current_user.id if current_user
      message[:oim_id] = current_user.oim_id if current_user
      message[:url] = request.original_url
      message[:params] = params if params
      log(message, :severity=>'error')
    end

    def after_sign_in_path_for(resource)
      session[:portal] || request.referer || root_path
    end

    def after_sign_out_path_for(resource_or_scope)
      logout_saml_index_path
    end

    def authenticate_user_from_token!
      user_token = params[:user_token].presence
      user = user_token && User.find_by_authentication_token(user_token.to_s)
      if user
        sign_in user, store: false
        flash[:notice] = "Signed in Successfully."
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

    def set_current_user
      User.current_user = current_user
      SAVEUSER[:current_user_id] = current_user.try(:id)
      session_id = SessionTaggedLogger.extract_session_id_from_request(request)
      unless SessionIdHistory.where(session_id: session_id).present?
        SessionIdHistory.create(session_id: session_id, session_user_id: current_user.try(:id))
      end
    end

    def clear_current_user
      User.current_user = nil
      SAVEUSER[:current_user_id] = nil
    end

    append_after_action :clear_current_user

    def set_current_person(required: true)
      if current_user.try(:person).try(:agent?)
        @person = session[:person_id].present? ? Person.find(session[:person_id]) : nil
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

    def actual_user
      if current_user.try(:person).try(:agent?)
        real_user = nil
      else
        real_user = current_user
      end
      real_user
    end

    def market_kind_is_employee?
      /employee/.match(current_user.last_portal_visited) || (session[:last_market_visited] == 'shop' && !(/consumer/.match(current_user.try(:last_portal_visited))))
    end

    def market_kind_is_consumer?
      /consumer/.match(current_user.last_portal_visited) || (session[:last_market_visited] == 'individual' && !(/employee/.match(current_user.try(:last_portal_visited))))
    end

    def save_bookmark (role, bookmark_url)
      if role && bookmark_url && (role.try(:bookmark_url) != family_account_path)
        role.bookmark_url = bookmark_url
        role.try(:save!)
      elsif bookmark_url.match('/families/home') && @person.present?
        @person.consumer_role.update_attribute(:bookmark_url, family_account_path) if (@person.consumer_role.present? && @person.consumer_role.bookmark_url != family_account_path)
        @person.employee_roles.last.update_attribute(:bookmark_url, family_account_path) if (@person.employee_roles.present? && @person.employee_roles.last.bookmark_url != family_account_path)
      end
    end
    def set_bookmark_url(url=nil)
      set_current_person
      bookmark_url = url || request.original_url
      if /employee/.match(bookmark_url)
        role = @person.try(:employee_roles).try(:last)
      elsif /consumer/.match(bookmark_url)
        role = @person.try(:consumer_role)
      end
      save_bookmark role, bookmark_url
    end

    def set_employee_bookmark_url(url=nil)
      set_current_person
      role = @person.try(:employee_roles).try(:last)
      bookmark_url = url || request.original_url
      save_bookmark role, bookmark_url
      session[:last_market_visited] = 'shop'
    end

    def set_consumer_bookmark_url(url=nil)
      set_current_person
      role = @person.try(:consumer_role)
      bookmark_url = url || request.original_url
      save_bookmark role, bookmark_url
      session[:last_market_visited] = 'individual'
    end

    def stashed_user_password
      session["stashed_password"]
    end

    def authorize_for
      authorize(controller_name.classify.constantize, "#{action_name}?".to_sym)
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
end
