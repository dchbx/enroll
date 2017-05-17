module Effective
  module Datatables
    class GeneralAgencyFamilyDataTable < Effective::MongoidDatatable
      attr_reader :person_cache

      datatable do
        table_column :name, :label => 'Name', :proc => Proc.new { |row| 
          pp = @effective_datatable.person_cache[row.primary_applicant.person_id]
          link_to pp.full_name, resume_enrollment_exchanges_agents_path(person_id: pp.id)
           }, :filter => false, :sortable => false

        table_column :ssn, :label => 'SSN', :proc => Proc.new { |row| 
             pp = @effective_datatable.person_cache[row.primary_applicant.person_id]
             primary_ssn = pp.ssn
             primary_ssn.blank? ? "" : number_to_obscured_ssn(primary_ssn)
         }, :filter => false, :sortable => false

        table_column :dob, :label => 'DOB', :proc => Proc.new { |row| 
          pp = @effective_datatable.person_cache[row.primary_applicant.person_id]
          format_date(pp.dob) }, :filter => false, :sortable => false
        
        table_column :hbx_id, :label => 'HBX ID', :proc => Proc.new { |row|
         pp = @effective_datatable.person_cache[row.primary_applicant.person_id]
         pp.hbx_id  }, :filter => false, :sortable => false
        
        table_column :family_ct, :label => 'Family Ct', :proc => Proc.new { |row| row.active_family_members.size }, :filter => false, :sortable => false
        
        table_column :consumer, :label => 'Consumer?', :proc => Proc.new {  |row|  
          pp = @effective_datatable.person_cache[row.primary_applicant.person_id]
          pp.consumer_role.present?  ? "Yes" : "No"}, :filter => false, :sortable => false

        table_column :employee, :label => 'Employee?', :proc => Proc.new {  |row|  
          pp = @effective_datatable.person_cache[row.primary_applicant.person_id]
          pp.employee_roles.present?  ? "Yes" : "No" }, :filter => false, :sortable => false
      end

      def collection
        @collection ||= Queries::GeneralAgencyFamiliesQuery.new(attributes[:id])
      end

      def global_search?
        true
      end

      # Override the callback to allow caching of sub-queries
      def arrayize(collection)
        return collection if @already_ran_caching
        @already_ran_caching = true
        @person_cache = {}
        primary_applicant_ids = []
        collection.each do |fam|
          primary_applicant_ids << fam.primary_applicant.person_id
        end
        Person.where("_id" => {"$in" => primary_applicant_ids}).each do |pers|
          @person_cache[pers.id] = pers
        end
        super(collection)
      end
    end
  end
end
