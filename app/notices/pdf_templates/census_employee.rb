module PdfTemplates
  class CensusEmployee
    include Virtus.model

    attribute :date_of_termination, Date
    attribute :coverage_terminated_on, Date
    attribute :enrollments, Array[PdfTemplates::Enrollment]

    def shop?
      return true
    end

    def health_enrollment
      if enrollments.present? && enrollments.detect{ |h| h.plan.coverage_kind == 'health'}.present?
        enrollments.detect{ |h| h.plan.coverage_kind == 'health'}
      end
    end

    def dental_enrollment
      if enrollments.present? && enrollments.detect{ |h| h.plan.coverage_kind == 'dental'}.present?
        enrollments.detect{ |h| h.plan.coverage_kind == 'dental'}
      end
    end
  end
end