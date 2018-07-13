module Effective
  module Datatables
    class ExampleDatatable < Effective::Datatable
      datatable do
        array_column :id
        array_column :first_name
        array_column :last_name
        array_column :email
      end

      def collection
        [
          [1, 'June', 'Huang', 'june@einstein.com'],
          [2, 'Leo', 'Stubbs', 'leo@einstein.com'],
          [3, 'Quincy', 'Pompey', 'quincy@einstein.com'],
          [4, 'Annie', 'Wojcik', 'annie@einstein.com'],
        ]
      end
    end
  end
end
