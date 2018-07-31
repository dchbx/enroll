module Queries
  class UserDatatableQuery
  	attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
    end

    def build_scope()
      user = klass
      users = case @custom_attributes[:users]
        when "all_employer_staff_roles"
          if @custom_attributes[:lock_unlock] == "locked"
            user.where(:'roles'.in => ["employer_staff"], :locked_at.ne => nil)
          elsif @custom_attributes[:lock_unlock] == "unlocked"
            user.where(:'roles'.in => ["employer_staff"], locked_at: nil)
          else
            user.where(:'roles'.in => ["employer_staff"])
          end
        when "all_employee_roles"
          if @custom_attributes[:lock_unlock] == "locked"
            user.where(:'roles'.in => ["employee"], :locked_at.ne => nil)
          elsif @custom_attributes[:lock_unlock] == "unlocked"
            user.where(:'roles'.in => ["employee"], locked_at: nil)
          else
            user.where(:'roles'.in => ["employee"])
          end
        when "all_broker_roles"
          if @custom_attributes[:lock_unlock] == "locked"
            user.where(:'roles'.in => ["broker"], :locked_at.ne => nil)
          elsif @custom_attributes[:lock_unlock] == "unlocked"
            user.where(:'roles'.in => ["broker"], locked_at: nil)
          else
            user.where(:'roles'.in => ["broker"])
          end
        when "all"
          if @custom_attributes[:lock_unlock] == "locked"
            user.locked
          elsif @custom_attributes[:lock_unlock] == "unlocked"
            user.unlocked
          else
            user.all
          end
        else
          if @search_string.present?
            user.datatable_search(@search_string)
          else
            user.all
          end
        end
        users
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

    def klass
      User
    end

    def size
      build_scope.count
    end
  end
end
