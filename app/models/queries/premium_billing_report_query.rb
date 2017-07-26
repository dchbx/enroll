module Queries
  class PremiumBillingReportQuery
    attr_reader :search_string
    attr_reader :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(enroll_ids)
      @hbx_enrollment_ids = enroll_ids
      
    end

    def skip(num)
      build_scope.skip(num)
    end

    def limit(num)
      build_scope.limit(num)
    end

    def klass
      Person
      Family
    end

    def size
      build_scope.count
    end

    def order_by(var)
      @order_by = var
      self
    end

    def build_scope
      enrollment_ids = {"households.hbx_enrollments._id" => {"$in" => @hbx_enrollment_ids}}
      if @search_string
        employee_roles = Person.any_of({ :first_name => /.*#{@search_string}.*/ }, { :last_name => /.*#{@search_string}.*/ }).collect{|p| p.employee_roles.pluck(:_id)}.flatten
        enrollment_ids = {
          "$and" => [
            { 'households.hbx_enrollments.employee_role_id' => {"$in" => employee_roles} },
            enrollment_ids 
          ]
        }
      end
      # if @order_by
      #   return Family.unscoped.where(criteria).order_by(@order_by)
      # end
      Family.unscoped.where(enrollment_ids).order_by(:'households.hbx_enrollments._id'.asc)
    end

  end
end
