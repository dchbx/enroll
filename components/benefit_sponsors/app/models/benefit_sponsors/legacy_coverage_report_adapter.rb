module BenefitSponsors
  class LegacyCoverageReportAdapter
    include Enumerable
    attr_accessor :pipeline, :sponsored_benefit
    def initialize(criterias)
      @criterias = criterias
    end

    def each
      iteration_index = 0
      yielded_so_far = 0
      skip_amount = @skip || 0
      record_limit = @limit || 100000000
      @criterias.each do |criteria|
        s_benefit, query = criteria
        query_ids = query.lazy.map { |q| q["hbx_enrollment_id"] }
        calculator = HbxEnrollmentSponsorEnrollmentCoverageReportCalculator.new(s_benefit, query_ids)
        calculator.each do |calc_result|
          iteration_index = iteration_index + 1
          next if iteration_index <= skip_amount
          next if yielded_so_far >= record_limit
          yield calc_result
          yielded_so_far = yielded_so_far + 1
        end
      end
    end

    def size
      return 0 if @criterias.empty?
      @count ||= begin
                   @criterias.inject(0) do |acc, criteria|
                     acc + criteria.last.count
                   end
                 end
    end

    def datatable_search(str)
      @sponsored_benefit = @criterias.first[0]
      @pipeline = @criterias.first[1].pipeline
      search_collection(str)
      self
    end

    def search_collection(str)
      employee_role_ids = Person.where(
        :"employee_roles.benefit_sponsors_employer_profile_id" => sponsored_benefit.benefit_sponsorship.profile_id,
        :"$or" => [
          {first_name: /#{str}/i}, {last_name: /#{str}/i}
        ]
      ).map(&:employee_roles).flatten.map(&:id)
      add({"$match" => {
        "hbx_enrollments.employee_role_id" => {"$in" => employee_role_ids}
      }})
    end

    def add(step)
      pipeline << step.to_hash
    end

    def order_by(opts = {})
      self
    end

    def skip(num)
      @skip = num
      self
    end

    def limit(num)
      @limit = num
      self
    end
  end
end
