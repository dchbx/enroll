module Queries
  class PremiumBillingReportQuery
    attr_reader :search_string
    attr_reader :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(hb_ids)
      @hbx_ids = hb_ids
      
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
       hbx_idss = {"households.hbx_enrollments._id" => {"$in" => @hbx_ids}}
      if @search_string
        employe_roles = Person.any_of({ :first_name => /.*#{@search_string}.*/ }, { :last_name => /.*#{@search_string}.*/ }).collect{|p| p.employee_roles.pluck(:_id)}.flatten
        hbx_idss = {
          "$and" => [
            { 'households.hbx_enrollments.employee_role_id' => {"$in" => employe_roles} },
            hbx_idss 
          ]
        }
      end
      # if @order_by
      #   return Family.unscoped.where(criteria).order_by(@order_by)
      # end
       Family.unscoped.where(hbx_idss).order_by(:'households.hbx_enrollments._id'.asc)
    end

  end
end
