module SponsoredApplications
  class Aca::DcEmployerApplication < Aca::EmployerApplication


    def add_marketplace_kind=(marketplace_kind)
      raise "marketplace must be aca_shop" unless marketplace_kind == :aca_shop
    end

    def add_sponsored_application
      raise "" if effective_term.blank?
    end


  end
end
