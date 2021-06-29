# frozen_string_literal: true

module Api
  module V2
    class UsersController < ApiBaseController
      def current
        op = Operations::SerializeCurrentUserResource.new(current_user)
        render json: op.call, status: :ok
      end
    end
  end
end