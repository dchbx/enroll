# frozen_string_literal: true

module Etl
  module Csv
    class Base

      # extend ActiveModel::Naming
      # include ActiveModel::Conversion
      # include ActiveModel::Validations

      attr_accessor :file, :employer_profile

      def initialize(attributes = {})
        attributes.each { |name, value| send("#{name}=", value) }

        # @column_headers = column_headers if defined?(@column_headers)
        # @header_row     = 0 unless defined?(@header_row)
        @data_start_row = 1 # unless defined?(@data_start_row)

        raise ArgumentError, "Must provide an import file" unless defined?(@file)
      end

      def persisted?
        false
      end

      def imported_records
        @imported_records ||= load_records
      end

      def load_records
        # file = 'spec/test_data/spreadsheet_templates/DCHL Employee Census.xlsx'
        excel_file = Roo::Spreadsheet.open(@file)

        @sheet = excel_file.sheet(0)
        # raise "Error: invalid header format." unless ((@header_row > 0) && header_valid?)

        # To match spreadsheet convention, Roo gem uses 1-based (rather than 0-based) references
        records = []
        documents = []
        @data_start_row = 2
        (@data_start_row..@sheet.last_row).map do |i|

          row = Hash[[ordered_column_names, excel_file.row(i)].transpose]

          record = parse_row(row)
          records << record

          document = map_attributes(record)
          puts "processed: #{document.npn}"
  # puts "***"
  # puts "#{document.inspect} #{document.person.inspect}  #{document.broker_agency_profile.inspect}"
  # puts " "
          documents << document
        end

        puts "Processed #{records.size} records from spreadsheet."
        puts "Successfully added or updated #{documents.size} database documents"

        documents
      end

      # Override this method with content-specific logic
      def header_valid?
        true
      end

      # Override this method with content-specific logic
      def parse_row(row); end

      # Override this method with content-specific logic
      def map_attributes(record); end


    ## Common Parsers

      def parse_ssn(cell)
        return nil unless cell.present?
        ssn = cell.to_s.gsub(/\D/, '')

        raise ImportErrorValue, "invalid SSN length: #{ssn.size}" unless ssn.size == 9
        raise ImportErrorValue, "invalid SSN composition #{ssn}" unless is_ssn_composition_valid?(ssn)
      end

      def parse_phone_number(cell)
        return nil if cell.blank?

        phone_number = cell.to_s.gsub(/\D/, '')
        raise ImportErrorValue, "invalid phone number length (#{phone_number.size}): #{phone_number}" if phone_number.size < 10 || phone_number.size > 11
        phone_number
      end

      def parse_employee_relationship(cell)
        # defined? @last_employer_assigned_family_id ?
        return nil if cell.blank?
        case parse_text(cell).downcase
        when "employee"
          "self"
        when "spouse"
          "spouse"
        when "domestic partner"
          "domestic_partner"
        when "child"
          "child"
        when "disabled child"
          "disabled_child"
        else
          nil[]
        end
      end

      def parse_text(cell)
        cell.blank? ? nil : sanitize_value(cell)
      end

      def parse_date(cell)
        return nil if cell.blank?

        if cell.instance_of?(String)
          begin
            return DateTime.strptime(cell.sanitize_value, "%d/%m/%Y")
          rescue StandardError
            raise ImportErrorValue, cell
          end
        end
        if cell.instance_of?(String)
          begin
            return cell.to_s.sanitize_value.to_time.strftime("%m-%d-%Y")
          rescue StandardError
            raise ImportErrorDate, cell
          end
        end
        # return cell.sanitize_value.to_date.to_s(:db) rescue raise ImportErrorValue, cell if cell.class == String

        cell.blank? ? nil : cell
      end

      def parse_boolean(cell)
        if cell.blank?
          nil
        else
          cell.match(/(true|t|yes|y|1)$/i).nil? ? "0" : "1"
        end
      end

      def parse_boolean(cell)
        if cell.blank?
          nil
        else
          cell.match(/(true|t|yes|y|1)$/i).nil? ? "0" : "1"
        end
      end

      def parse_number(cell)
        if cell.blank?
          nil
        else
          begin
            Float(cell)
          rescue StandardError
            raise ImportErrorValue, cell
          end
        end
      end

      def parse_integer(cell)
        if cell.blank?
          nil
        else
          begin
            Integer(cell)
          rescue StandardError
            raise ImportErrorValue, cell
          end
        end
      end

      def save
        if imported_records.map(&:valid?).all?
          imported_records.each(&:save!)
          true
        else
          imported_records.each_with_index do |census_employee, index|
            census_employee.errors.full_messages.each do |message|
              errors.add :base, "Row #{index + 2}: #{message}"
            end
          end
          false
        end
      end

      def open_spreadsheet
        case File.extname(file.original_filename)
        when ".csv"
          Csv.new(file.path, nil, :ignore)
        when ".xls"
          Excel.new(file.path, nil, :ignore)
        when ".xlsx"
          Excelx.new(file.path, nil, :ignore)
        else
          raise "Unknown file type: #{file.original_filename}"
        end
      end

      def length
        @imported_records.length
      end

      alias count length

      private

      def sanitize_value(value)
        value = value.to_s.split('.')[0] if value.is_a? Float
        value.gsub(/[[:cntrl:]]|^\p{Space}+|\p{Space}+$/, '')
      end

      def is_ssn_composition_valid?(ssn)
        return nil unless ssn.present?
        # Invalid compositions:
        #   All zeros or 000, 666, 900-999 in the area numbers (first three digits);
        #   00 in the group number (fourth and fifth digit); or
        #   0000 in the serial number (last four digits)

        invalid_area_numbers = %w[000 666]
        invalid_area_range = 900..999
        invalid_group_numbers = %w[00]
        invalid_serial_numbers = %w[0000]

        return false if ssn.to_s.blank?
        return false if invalid_area_numbers.include?(ssn.to_s[0,3])
        return false if invalid_area_range.include?(ssn.to_s[0,3].to_i)
        return false if invalid_group_numbers.include?(ssn.to_s[3,2])
        return false if invalid_serial_numbers.include?(ssn.to_s[5,4])

        true
      end
    end

    class ImportErrorValue < RuntimeError; end

    class ImportErrorDate < RuntimeError; end
  end
end
