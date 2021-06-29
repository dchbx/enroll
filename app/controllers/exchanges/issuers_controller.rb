# frozen_string_literal: true

module Exchanges
  class IssuersController < HbxProfilesController
    before_action :check_hbx_staff_role, only: [:index]
    before_action :check_issuers_tab_enabled, only: [:index]



    def index
      issuers = ::BenefitSponsors::Services::IssuerDataTableService.new
      table_data = issuers.retrieve_table_data
      @data = ::BenefitSponsors::Serializers::IssuerDatatableSerializer.new(table_data).serialized_json
      respond_to do |format|
        format.js
        format.json { render json: @data }
      end
    end

    private

    def check_issuers_tab_enabled
      redirect_to root_path, notice: "Issuers tab not enabled" unless EnrollRegistry.feature_enabled?(:issuers_tab)
    end

  end
end
