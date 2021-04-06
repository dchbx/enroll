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
        _load  =  yield import_records(headers, sheet)
        Success()
      end

      private

      def validate(params)
        return Failure('Missing File') if params[:file].blank?
        return Failure('Missing Import TimeStamp') if params[:import_timestamp].blank?
        Success(params)
      end

      def load_data
        result = Roo::Spreadsheet.open(params[:file])
        sheet = result.sheet(0)
        Success(sheet)
      end

      def load_headers
        header_row = sheet_data.row(1)
        headers = Hash.new
        header_row.each_with_index {|header,i|
          headers[header.to_s.underscore] = i
        }
        Success(headers)
      end

      def import_records(headers, sheet)
        begin
          (2..sheet.last_row).each do |row_number|
            row_info = sheet.row(row_number)
            # Get these form RR
            state_abbreviation = 'ME'
            geographic_rating_area_model = 'county'
            query_criteria = { state: state_abbreviation }
            query_criteria.merge!({ zip: row_info[headers["zip"]].squish! }) if geographic_rating_area_model != 'county'
            query_criteria.merge!({ county_name: row_info[headers['county']].squish! }) if geographic_rating_area_model != 'zipcode'
            existing_county = ::BenefitMarkets::Locations::CountyZip.where(query_criteria)
            next if existing_county.present?

            params = query_criteria.merge!({created_at: params[:import_timestamp]})
            ::BenefitMarkets::Locations::CountyZip.new(params).save!
          end
        rescue
          return Failure({errors: ["Unable to import CountyZips from file"]})
        end
        Success('Created CountyZips for given data')
      end
    end
  end
end
