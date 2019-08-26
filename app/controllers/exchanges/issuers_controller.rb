# frozen_string_literal: true

module Exchanges
  class IssuersController < HbxProfilesController
    before_action :check_hbx_staff_role, only: [:index]

    def index
      authorize HbxProfile, :can_upload_sbc?
      issuers = ::BenefitSponsors::Services::IssuerDataTableService.new
      table_data = issuers.retrieve_table_data
      @data = ::BenefitSponsors::Serializers::IssuerDatatableSerializer.new(table_data).serialized_json
      respond_to do |format|
        format.js
        format.json { render json: @data }
      end
    end
  end
end
