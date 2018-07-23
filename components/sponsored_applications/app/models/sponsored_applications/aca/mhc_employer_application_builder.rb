module SponsoredApplications
  class Aca::MhcEmployerApplicationBuilder

    def add_recorded_sic_code(new_recorded_sic_code)
      @sponsored_application.recorded_sic_code = new_recorded_sic_code
    end

    def add_recorded_rating_area(new_recorded_rating_area)
      @sponsored_application.recorded_rating_area = new_recorded_rating_area
    end


  end
end
