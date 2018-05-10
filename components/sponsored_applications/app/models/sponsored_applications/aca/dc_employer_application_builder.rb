module SponsoredApplications
  class Aca::DcEmployerApplicationBuilder < SponsoredApplications::SponsoredApplicationBuilder

    def initialize
      @sponsored_application = Aca::DcEmployerApplication.new
      add_kind(:dc_employer)
    end

    def sponsored_application
      @sponsored_application
    end

  end
end
