module SponsoredApplications
  class BenefitGroup
    include Mongoid::Document


    field :title, type: String, default: ""
    field :description, type: String, default: ""

  end
end
