class Products::QhpMaximumOutOfPocket
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :qhp_cost_share_variance

  # Benefit name
  field :name, type: String   
  field :in_network_tier_1_individual_amount, type: String
  field :in_network_tier_1_family_amount, type: String
  field :in_network_tier_2_individual_amount, type: String
  field :in_network_tier_2_family_amount, type: String
  field :out_of_network_individual_amount, type: String
  field :out_of_network_family_amount, type: String
  field :combined_in_out_network_individual_amount, type: String
  field :combined_in_out_network_family_amount, type: String

end
