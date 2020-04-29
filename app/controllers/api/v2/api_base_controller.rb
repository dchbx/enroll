module Api
  module V2
    class ApiBaseController < ActionController::Base
      include Pundit

      protect_from_forgery with: :null_session, prepend: true

      before_action :require_login

      def require_login
        unless current_user
          render file: 'public/403.html', status: 403
          return
        end
      end
    end
  end
end