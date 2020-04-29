module Api
  module V2
    class AuthTokensController < ApiBaseController
      def logout
        current_user.revoke_all_jwts!
        head :ok
      end

      def refresh
        token = current_user.generate_jwt(warden.config[:default_scope], 'admin')
        reply_body = {
          jwt: token
        }
        render json: reply_body
      end
    end
  end
end