# frozen_string_literal: true

module Operations
  module Products
    # This class is to load county zip combinations.
    class ImportCountyZip
      include Dry::Monads[:result, :do]

      def call(params)
        values  = yield validate(params)
        sheet   = yield load_data(values[:file])
        headers = yield load_headers(sheet)
        _load  =  yield import_records(headers, sheet, values[:import_timestamp])
        Success()
      end

      private

      def validate(params)
        return Failure('Missing File') if params[:file].blank?
        return Failure('Missing Import TimeStamp') if params[:import_timestamp].blank?
        Success(params)
      end

      def load_data(file)
        result = Roo::Spreadsheet.open(file)
        sheet = result.sheet(0)
        Success(sheet)
      end

      def load_headers(sheet)
        header_row = sheet.row(1)
        headers = {}
        header_row.each_with_index do |header,i|
          headers[header.to_s.underscore] = i
        end
        Success(headers)
      end

      def import_records(headers, sheet, import_timestamp)
        state_abbreviation = EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
        geographic_rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item
        return Success("CountyZips not needed") if geographic_rating_area_model == 'single'
        begin
          (2..sheet.last_row).each do |row_number|
            row_info = sheet.row(row_number)
            query_criteria = { state: state_abbreviation, county_name: row_info[headers['county']].squish!, zip: row_info[headers["zip"]].squish! }

            existing_county = ::BenefitMarkets::Locations::CountyZip.where(query_criteria)
            next if existing_county.present?
            query_criteria.merge!({ created_at: import_timestamp })

            ::BenefitMarkets::Locations::CountyZip.new(query_criteria).save!
          end
        rescue StandardError
          return Failure({errors: ["Unable to import CountyZips from file"]})
        end
        Success('Created CountyZips for given data')
      end
    end
  end
end
