module SponsoredApplications
  class Aca::MhcEmployerApplication  < Aca::EmployerApplication

    # SIC code, frozen when the plan year is published,
    # otherwise comes from employer_profile
    field :recorded_sic_code, type: String
    field :recorded_rating_area, type: String



  end
end
