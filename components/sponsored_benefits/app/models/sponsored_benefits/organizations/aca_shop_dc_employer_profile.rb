module SponsoredBenefits
  module Organizations
    class AcaShopDcEmployerProfile < Profile

      field :profile_source, type: String, default: "broker_quote"
      field :contact_method, type: String, default: "Only Electronic communications"

      embeds_one :general_agency_profile, cascade_callbacks: true, validate: true

    end
  end
end
