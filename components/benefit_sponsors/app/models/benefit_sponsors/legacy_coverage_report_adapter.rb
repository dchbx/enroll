module BenefitSponsors
  class LegacyCoverageReportAdapter
    include Enumerable
    attr_accessor :pipeline, :sponsored_benefit
    def initialize(criterias)
      @criterias = criterias
    end

    def each
      @criterias.each do |criteria|
        s_benefit, query = criteria
        query_ids = query.lazy.map { |q| q["hbx_enrollment_id"] }
        calculator = HbxEnrollmentSponsorEnrollmentCoverageReportCalculator.new(s_benefit, query_ids)
        calculator.each do |calc_result|
          yield calc_result
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

      add({"$project" => {"hbx_enrollments": 1}})
      add({"$match" => {
        "hbx_enrollments.employee_role_id" => {"$in" => employee_role_ids}
      }})
      add({"$group" => {
        "_id" => {
          "bga_id" => "$hbx_enrollments.sponsored_benefit_id",
          "employee_role_id" => "$hbx_enrollments.employee_role_id"
        },
        "hbx_enrollment_id" => {"$last" => "$hbx_enrollments._id"}
      }})
    end

    def add(step)
      pipeline << step.to_hash
    end

    def order_by(opts = {})
      self
    end

    def skip(num)
      self
    end

    def limit(num)
      self
    end
  end
end
