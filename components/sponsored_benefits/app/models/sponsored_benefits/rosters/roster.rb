module SponsoredBenefits
  class Rosters::Roster
    include Mongoid::Document

    belongs_to :rosterable, polymorphic: true
  end
end
