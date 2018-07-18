module Effective
  module Datatables
    class DocumentDatatable < Effective::MongoidDatatable
      datatable do

        bulk_actions_column do
          bulk_action 'Download'
          bulk_action 'Delete', data: {  confirm: 'Are you sure?', no_turbolink: true }
        end
        table_column :status, :proc => Proc.new { |row|
          document = attestation_document(row)
          document.present? ? document.aasm_state.camelcase : nil
        }, :filter => false, :sortable => false
        table_column :employer, :proc => Proc.new { |row|
          @employer_profile = row.employer_profile
          (link_to row.legal_name.titleize, employers_employer_profile_path(@employer_profile, :tab=>'home'))
        }, :sortable => false, :filter => false
        table_column :doc_type, :proc => Proc.new { |row| link_to "Employer Attestation","", "data-toggle" => "modal", 'data-target' => "#employeeModal_#{row.id}"  }, :filter => false, :sortable => false
        table_column :effective_date, :proc => Proc.new { |row| "effective date" }, :filter => false, :sortable => false
        table_column :submitted_date, :proc => Proc.new { |row| 
          document = attestation_document(row)
          document.present? ? document.created_at.strftime('%m/%d/%Y') : nil
        }, :filter => false, :sortable => false
      end

      def attestation_document(row)
        attestation = row.employer_profile.employer_attestation
        if attestation.present?
          if attributes[:aasm_state].present?
            attestation_doc = attestation.employer_attestation_documents.where(:aasm_state => attributes[:aasm_state]).last
          else
            attestation_doc = attestation.employer_attestation_documents.last
          end
        end
        attestation_doc
      end

      def generate_invoice_link_type(row)
        row.current_month_invoice.present? ? 'disabled' : 'post_ajax'
      end

      def collection
        organizations = Organization.all_employer_profiles.employer_profiles_with_attestation_document
        if attributes[:aasm_state].present?  
          organizations.where(:"employer_profile.employer_attestation.employer_attestation_documents.aasm_state" => attributes[:aasm_state])
        else
          organizations
        end
      end

      def global_search?
        false
      end

      def global_search_method
        val = params[:search][:value]
        if val.match(/\d{9}/)
          :datatable_search_fein
        else
          :datatable_search
        end
      end

      def search_column(collection, table_column, search_term, sql_column)

      end

    def nested_filter_definition
      {
          top_scope:  :aasm_state,
          aasm_state: [
              {label: 'All'},
              {scope: "submitted",label: 'Submitted'},
              {scope: "accepted",label: 'Accepted'},
              {scope: "rejected",label: 'Rejected'},
          ],
      }
      end
    end
  end
end
