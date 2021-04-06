# frozen_string_literal: true

module Operations
  module Products
    # This class is to load county zip combinations.
    class ImportRatingArea
      include Dry::Monads[:result, :do]

      def call(params)
        values  = yield validate(params)
        data    = yield load_data(values[:file])
        _load   =  yield import_records(data, values[:year])
        Success()
      end

      private

      def validate(params)
        return Failure('Missing File') if params[:file].blank?
        return Failure('Missing Year') if params[:year].blank?
        return Failure('Missing Import TimeStamp') if params[:import_timestamp].blank?
        Success(params)
      end

      def load_data
        result = Roo::Spreadsheet.open(params[:file])
        sheet = result.sheet(0)
        result = Hash.new {|results, k| results[k] = []}

        if geographic_rating_area_model == 'county'
          (2..sheet.last_row).each do |i|
            result[sheet.cell(i, 4)] << { 'county_name' => sheet.cell(i, 2) }
          end
        elsif geographic_rating_area_model == 'zipcode'
          (2..sheet.last_row).each do |i|
            result[sheet.cell(i, 4)] << { 'zip' => sheet.cell(i, 1) }
          end
        else
          (2..sheet.last_row).each do |i|
            result[sheet.cell(i, 4)] << {
              'county_name' => sheet.cell(i, 2),
              'zip' => sheet.cell(i, 1)
            }
          end
        end
        Success(result)
      end

      def import_records(data, year)
        state_abbreviation = 'ME'
        geographic_rating_area_model = 'county'
        begin
          data.each do |rating_area_id, locations|
            location_ids = locations.map do |loc_record|
              query_criteria = {
                                 state: state_abbreviation,
                                 county_name: loc_record['county_name']
                               }
              query_criteria.merge!({ zip: loc_record['zip'] }) unless geographic_rating_area_model == 'county'
              query_criteria.merge!({ county_name: loc_record['county'] }) unless geographic_rating_area_model == 'zipcode'
              county_zip = ::Locations::CountyZip.where(query_criteria).first
              county_zip._id
            end

            rating_area = ::Locations::RatingArea.where(
              {
                active_year: year,
                exchange_provided_code: rating_area_id
              }
            ).first
            if rating_area.present?
              rating_area.county_zip_ids = location_ids
              rating_area.save!
            else
              ::Locations::RatingArea.new(
                {
                  created_at: import_timestamp,
                  active_year: year,
                  exchange_provided_code: rating_area_id,
                  county_zip_ids: location_ids
                }
              ).save!
            end
          end
        rescue
          return Failure({errors: ["Unable to import CountyZips from file"]})
        end
        Success('Created Rating Areas for given data')
      end
    end
  end
end
