module PdfTemplates
  class ConditionalEligibilityNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :notice_date, Date
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :enrollments, Array[PdfTemplates::Enrollment]
    attribute :individuals, Array[PdfTemplates::Individual]
    attribute :ssa_unverified, Array[PdfTemplates::Individual]
    attribute :dhs_unverified, Array[PdfTemplates::Individual]
    attribute :first_name, String
    attribute :last_name, String
    attribute :due_date, String

    def other_enrollments
      enrollments.reject{|enrollment| enrollments.index(enrollment).zero? }
    end

    def shop?
      false
    end

    def verified_individuals
      individuals.select{|individual| individual.verified }
    end

    def unverified_individuals
      individuals.reject{|individual| individual.verified }
    end

    def ssn_unverified
      individuals.reject{|individual| individual.ssn_verified}
    end

    def citizenship_unverified
      individuals.reject{|individual| individual.citizenship_verified}
    end

    def residency_unverified
      individuals.reject{|individual| individual.residency_verified}
    end

    def indian_conflict
      individuals.select{|individual| individual.indian_conflict}
    end

    def incarcerated
      individuals.select{|individual| individual.incarcerated}
    end

    def current_health_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "health" && enrollment.effective_on.year == Date.today.year}
    end

    def current_dental_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "dental" && enrollment.effective_on.year == Date.today.year}
    end

    def renewal_health_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "health" && enrollment.effective_on.year == Date.today.next_year.year}
    end

    def renewal_dental_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "dental" && enrollment.effective_on.year == Date.today.next_year.year}
    end
  end
end