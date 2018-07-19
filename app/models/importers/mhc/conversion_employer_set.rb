module Importers::Mhc
  class ConversionEmployerSet
    def headers
      [
          "Action",
          "FEIN",
          "Doing Business As",
          "Legal Name",
          "Issuer Assigned Employer ID",
          "SIC code",
          "Physical Address 1",
          "Physical Address 2",
          "City",
          "County",
          "County FIPS code",
          "State",
          "Zip",
          "Mailing Address 1",
          "Mailing Address 2",
          "City",
          "State",
          "Zip",
          "Contact First Name",
          "Contact Last Name",
          "Contact Email",
          "Contact Phone",
          "Contact Phone Extension",
          "Enrolled Employee Count",
          "New Hire Coverage Policy",
          "Contact Address 1",
          "Contact Address 2",
          "City",
          "State",
          "Zip",
          "Broker Name",
          "Broker NPN",
          "TPA Name",
          "TPA FEIN",
          "Coverage Start Date",
          "Carrier Selected",
          "Plan Selection Category",
          "Plan Name",
          "Plan HIOS Id",
          "Employee Only Rating Tier Contribution",
          "Employee Rating Tier Premium",
          "Employee And Spouse Rating Tier Offered",
          "Employee And Spouse Rating Tier Contribution",
          "Employee And Spouse Rating Tier Premium",
          "Employee And Dependents Rating Tier Offered",
          "Employee And Dependents Rating Tier Contribution",
          "Employee And Dependents Rating Tier Premium",
          "Family Rating Tier",
          "Family Rating Tier Contribution",
          "Family Rating Tier Premium",
          "Import Status",
          "Import Details",
          "Organization assigned hbx_id"
      ]
    end

    def row_mapping
      [
          :action,
          :fein,
          :dba,
          :legal_name,
          :assigned_employer_id,
          :sic_code,
          :primary_location_address_1,
          :primary_location_address_2,
          :primary_location_city,
          :primary_location_county,
          :primary_location_county_fips,
          :primary_location_state,
          :primary_location_zip,
          :mailing_location_address_1,
          :mailing_location_address_2,
          :mailing_location_city,
          :mailing_location_state,
          :mailing_location_zip,
          :contact_first_name,
          :contact_last_name,
          :contact_email,
          :contact_phone,
          :contact_phone_extension,
          :enrolled_employee_count,
          :new_hire_count,
          :ignore,
          :ignore,
          :ignore,
          :ignore,
          :ignore,
          :broker_name,
          :broker_npn,
          :ignore,
          :ignore,
          :ignore,
          :ignore
      ]
    end

    include ::Importers::RowSet

    def initialize(file_name, o_stream, conversion_date)
      @spreadsheet = Roo::Spreadsheet.open(file_name)
      @out_stream = o_stream
      @out_csv = CSV.new(o_stream)
      @conversion_date = conversion_date
    end

    def create_model(record_attrs)
      row_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase
      if row_action == 'add'
        ::Importers::Mhc::ConversionEmployerCreate.new(record_attrs.merge({:registered_on => @conversion_date}))
      elsif row_action == 'update'
        ::Importers::Mhc::ConversionEmployerUpdate.new(record_attrs.merge({:registered_on => @conversion_date}))
      else
        ::Importers::Mhc::ConversionEmployerCreate.new(record_attrs.merge({:registered_on => @conversion_date}))
      end
    end
  end
end