# frozen_string_literal: true

module Api
  module V2
    class ApiBaseController < ActionController::Base
      include Pundit

      protect_from_forgery with: :null_session, prepend: true

      before_action :require_login

      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
      rescue_from Mongoid::Errors::DocumentNotFound, with: :record_find_failure

      def user_not_authorized(_exception)
        render file: 'public/403.html', status: 403
      end

      def record_find_failure(_exception)
        render file: 'public/404.html', status: 404
      end

      def require_login
        unless current_user
          render json: { status: "Unauthorized" }, status: 401
          nil
        end
      end
    end
  end
end