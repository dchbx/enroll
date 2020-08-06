# frozen_string_literal: true

module Effective
  module Datatables
    class IdentityVerificationDataTable < Effective::MongoidDatatable
      datatable do
        table_column :name, :label => 'Name', :proc => proc { |row| link_to row.full_name, resume_enrollment_exchanges_agents_path(person_id: row.id) }, :filter => false, :sortable => false
        table_column :ssn, :label => 'SSN', :proc => proc { |row| truncate(number_to_obscured_ssn(row.ssn))}, :filter => false, :sortable => false
        table_column :dob, :label => 'DOB', :proc => proc { |row| row.dob }, :filter => false, :sortable => false
        table_column :hbx_id, :label => 'HBX ID', :proc => proc { |row| row.hbx_id }, :filter => false, :sortable => false
        table_column :count, :label => 'Count', :width => '100px', :proc => proc { |row| row.primary_family.active_family_members.size  }, :filter => false, :sortable => false
        table_column :document_type, :label => 'Document Type', :proc => proc { |row| document_type(row) }, :filter => false, :sortable => false
        table_column :date_uploaded, :label => "Date Uploaded", :width => '100px', :proc => proc { |row| document_uploaded_date(row) }, :filter => false, :sortable => false
      end

      scopes do
        scope :legal_name, "Hello"
      end

      def collection
        @families = Queries::IdentityVerificationDatatableQuery.new(attributes) unless (defined? @families) && @families.present? #memoize the wrapper class to persist @search_string
        @families
      end

      def global_search?
        true
      end

      def document_type(row)
        if row.consumer_role.application_validation == "outstanding" && row.consumer_role.identity_validation == "pending" || row.consumer_role.application_validation == "valid" && row.consumer_role.identity_validation == "pending"
          "Identity"
        elsif row.consumer_role.application_validation == "pending" && row.consumer_role.identity_validation == "outstanding" || row.consumer_role.application_validation == "pending" && row.consumer_role.identity_validation == "valid"
          "Application"
        elsif row.consumer_role.application_validation == "pending" && row.consumer_role.identity_validation == "pending"
          "Identity/Application"
        end
      end

      def document_uploaded_date(row)
        if row.consumer_role.identity_validation == "pending"
          ridp_document = row.consumer_role.ridp_documents.where(ridp_verification_type: "Identity").last
          ridp_document.present? && ridp_document.uploaded_at.present? ? ridp_document.uploaded_at : ""
        elsif row.consumer_role.application_validation == "pending"
          ridp_document = row.consumer_role.ridp_documents.where(ridp_verification_type: "Application").last
          ridp_document.present? && ridp_document.uploaded_at.present? ? ridp_document.uploaded_at : ""
        end
      end

    end
  end
end
