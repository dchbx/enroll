module RecaptchaConcern
  extend ActiveSupport::Concern

  included do
    prepend_before_action :check_captcha, only: [:create]

    private

    def check_captcha
      return unless Settings.aca.recaptcha_enabled && Rails.env.production?
      case self.class.to_s
      when 'Users::RegistrationsController'
        unless verify_recaptcha
          self.resource = resource_class.new sign_up_params
          resource.oim_id = params[:user][:oim_id]
          respond_with_navigational(resource) { render :new }
        end
      when 'Users::SessionsController'
        if User.login_captcha_required?(params[:user][:login])
          unless verify_recaptcha
            self.resource = resource_class.new
            resource.login = params[:user][:login]
            respond_with_navigational(resource) { render :new }
          end
        end
      end
    end

  end
end
