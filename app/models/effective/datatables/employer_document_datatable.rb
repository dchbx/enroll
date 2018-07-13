module Effective
  module Datatables
    class EmployerDocumentDatatable < Effective::MongoidDatatable
      datatable do

        table_column "Doc Status", :proc => Proc.new { |row|
          icon = ""

          if row.accepted?
            icon = "<span class='glyphicon glyphicon-ok text-success' aria-hidden='true' title='Approved'></span> "
          elsif row.reason_for_rejection.present?
            icon = "<span class='glyphicon glyphicon-exclamation-sign text-danger' aria-hidden='true' title='#{row.reason_for_rejection}'></span> "
          end

          raw(icon) + row.aasm_state.humanize
        }, :filter => false, :sortable => false
        table_column :name, :label => 'Doc Name', :proc => Proc.new { |row|
          link_to raw('<i class="fa fa-file-text-o pull-left"></i> ') + row.title, "", 'target' => "iframe_#{row.id}", 'data-target' => "#employeeModal_#{row.id}", "data-toggle" => "modal", "class" => "word-break-attestation"
        }, :filter => false, :sortable => false
        table_column :type, :label => 'Doc Type',:proc => Proc.new { |row|
           'Employer Attestation'
        }, :filter => false, :sortable => false
        table_column :size, :proc => Proc.new { |row| number_to_human_size(row.size, precision: 2) }, :filter => false, :sortable => false
        table_column :date, :label => 'Submitted At', :proc => Proc.new { |row| TimeKeeper.local_time(row.created_at).strftime('%m/%d/%Y %I:%M%p') }, :filter => false, :sortable => false
        table_column :actions, :width => '50px', :proc => Proc.new { |row|
           key, bucket = get_key_and_bucket(row.identifier)
          dropdown = [
           ['Download',  document_download_path(bucket, key)+ "?id=#{@employer_profile.id}&content_type=#{row.format}&filename=#{row.title.gsub(/[^0-9a-z]/i,'')}",'static'],
           ['Delete', employers_employer_attestation_delete_attestation_documents_path(row.id), (@employer_profile.employer_attestation.editable? && row.submitted?) ? 'delete ajax with confirm' : 'disabled',  'Do you want to Delete this document?']
          ]
          render partial: 'datatables/shared/dropdown', locals: {dropdowns: dropdown, row_actions_id: "employer_actions_#{@employer_profile.id}"}, formats: :html
        }, :filter => false, :sortable => false
      end


      def collection
        @employer_profile = EmployerProfile.find(attributes[:employer_profile_id])
        documents = EmployerAttestationDocument.none
        if @employer_profile.employer_attestation.present?
          documents = @employer_profile.employer_attestation.employer_attestation_documents
        end
        documents
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

    end
  end
end
