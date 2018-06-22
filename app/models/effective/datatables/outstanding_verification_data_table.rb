
module Effective
  module Datatables
    class OutstandingVerificationDataTable < Effective::MongoidDatatable
      datatable do
        table_column :name, :label => 'Name', :proc => Proc.new { |row| link_to row.primary_applicant.person.full_name, resume_enrollment_exchanges_agents_path(person_id: row.primary_applicant.person.id)}, :filter => false, :sortable => true
        table_column :ssn, :label => 'SSN', :proc => Proc.new { |row| truncate(number_to_obscured_ssn(row.primary_applicant.person.ssn)) }, :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :proc => Proc.new { |row| format_date(row.primary_applicant.person.dob)}, :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row| row.primary_applicant.person.hbx_id }, :filter => false, :sortable => false
        table_column :count, :label => 'Count', :width => '100px', :proc => Proc.new { |row| row.active_family_members.size }, :filter => false, :sortable => false
        table_column :documents_uploaded, :label => 'Documents Uploaded', :proc => Proc.new { |row| row.vlp_documents_status}, :filter => false, :sortable => true
        table_column :verification_due, :label => 'Verification Due',:proc => Proc.new { |row|  format_date(row.best_verification_due_date) || format_date(TimeKeeper.date_of_record + 95.days) }, :filter => false, :sortable => true
        table_column :actions, :width => '50px', :proc => Proc.new { |row|
          dropdown = [
           ["Review", show_docs_documents_path(:person_id => row.primary_applicant.person.id),"static"]
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "family_actions_#{row.id.to_s}"}, formats: :html
        }, :filter => false, :sortable => false

      end

      def collection
        unless  (defined? @families) && @families.present?   #memoize the wrapper class to persist @search_string
          @families = Queries::OutstandingVerificationDatatableQuery.new(attributes)
        end
        @families
      end

      def global_search?
        true
      end

      def date_filter_name_definition
        "Verification Due Date Range"
      end

      def nested_filter_definition
        filters = {
        documents_uploaded: [
          {scope: 'vlp_fully_uploaded', label: 'Fully Uploaded', title: "Documents to review for all outstanding verifications"},
          {scope: 'vlp_partially_uploaded', label: 'Partially Uploaded', title: "Documents to review for some outstanding verifications"},
          {scope: 'vlp_none_uploaded', label: 'None Uploaded', title: "No documents to review"},
          {scope: 'all', label: 'All', title: "All outstanding verifications"},
        ],
        top_scope: :documents_uploaded
        }
      end
    end
  end
end
