module Queries
  class EmployeeDatatableQuery
    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
      @employer_profile = BenefitSponsors::Organizations::Organization.employer_profiles.where(
        :"profiles._id" => BSON::ObjectId.from_string(@custom_attributes[:id])
      ).first.try(:employer_profile) || EmployerProfile.find(@custom_attributes[:id]) # Remove try when you deprecate old ER profile
    end

    def build_scope()
      return [] if @employer_profile.nil?
      collection = nil
      case @custom_attributes[:employers]
        when "active"
          collection = @employer_profile.census_employees.active
        when "active_alone"
          collection = @employer_profile.census_employees.active_alone
        when "by_cobra"
          collection = @employer_profile.census_employees.by_cobra
        when "terminated"
          collection = @employer_profile.census_employees.terminated
        when "all"
          collection = @employer_profile.census_employees
        else
          collection = @employer_profile.census_employees.active_alone
      end

      if @search_string.present?
        return collection.any_of(CensusEmployee.search_hash(@search_string))
      end

      return collection
    end


    def skip(num)
      build_scope.skip(num)
    end

    def limit(num)
      build_scope.limit(num)
    end

    def order_by(var)
      @order_by = var
      self
    end

    def any?
      build_scope.each do |e|
        return if yield(e)
      end
    end

    def klass
      Family
    end

    def size
      build_scope.count
    end
  end
end
