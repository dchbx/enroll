module SponsoredApplications
  class SponsoredApplicationBuilder

    attr_reader :sponsored_application

    def add_kind(new_kind)
      @sponsored_application.kind = new_kind
    end

    def add_effective_term(new_effective_term)
      @sponsored_application.effective_term = new_effective_term
    end

    def add_open_enrollment_term(new_open_enrollment_term)
      @sponsored_application.open_enrollment_term = new_open_enrollment_term
    end

    def add_benefit_group(new_benefit_group)
    end

    def reset
    end
  end
end
