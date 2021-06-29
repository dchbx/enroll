# frozen_string_literal: true

module Api
  module V1
    class ApiController < Api::V1::ApiBaseController

      def ping
        response = {
          ping: 'pong',
          whoami: 'Enroll API',
          version: 'v1'
        }
        render json: response
      end
    end
  end
end
