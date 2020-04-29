class Api::V1::BrokersController < Api::V1::ApiBaseController

  def index
    render json: BenefitSponsors::Organizations::Organization.broker_agency_profiles.limit(100).to_json
  end

  def broker_staff
    render json: BrokerStaffSerializer.new(Person.all_broker_staff_roles).serialized_json
  end

  def show
  end
end
