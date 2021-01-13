# frozen_string_literal: true

module Exchanges
  class ProductsController < HbxProfilesController
    before_action :check_hbx_staff_role

    def index
      @service = ::BenefitSponsors::Services::ProductDataTableService.new(issuer_params)
      table_data = @service.retrieve_table_data
      @data = ::BenefitSponsors::Serializers::ProductDatatableSerializer.new(table_data).serialized_json
      respond_to do |format|
        format.js
        format.json { render json: @data }
      end
    end

    private

    def issuer_params
      params.permit(:issuer_id, :query)
      { issuer_profile_id: params['issuer_id'], filter: params['query'] }
    end
  end
end