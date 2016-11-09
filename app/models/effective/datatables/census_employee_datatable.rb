module Effective
  module Datatables
    class CensusEmployees < Effective::Datatables
      datatable do



      end

      def collection
        #census_employe = #CensusEmployee.all
      end

      scopes do
        scope :legal_name, "Hello"
      end


      def global_search?
        true
      end

    end
  end
end