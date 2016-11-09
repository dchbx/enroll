module Effective
  module Datatables
    class CensusEmployeeDatatable < Effective::MongoidDatatable
      datatable do
        table_column :first_name
        table_column :last_name
        table_column :dob
        table_column :aasm_state
        # table_column #hired
        # table_column #benefit package
        # table_column #enrollment status
        # table_column #terminate
        # table_column #edit
      end

      def collection
        @census_employee = CensusEmployee.all
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