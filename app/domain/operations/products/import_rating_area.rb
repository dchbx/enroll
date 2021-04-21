# frozen_string_literal: true

module Operations
  module Products
    # This class is to load rating areas.
    class ImportRatingArea
      include Dry::Monads[:result, :do]

      def call(params)
        values  = yield validate(params)
        data    = yield load_data(values[:file])
        _load = yield import_records(data, values[:year], values[:import_timestamp])
        Success()
      end

      private

      def validate(params)
        return Failure('Missing File') if params[:file].blank?
        return Failure('Missing Year') if params[:year].blank?
        return Failure('Missing Import TimeStamp') if params[:import_timestamp].blank?
        Success(params)
      end

      def load_data(file)
        geographic_rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item
        result = Roo::Spreadsheet.open(file)
        sheet = result.sheet(0)
        result = Hash.new {|results, k| results[k] = []}

        case geographic_rating_area_model
        when 'single'
          result = {}
        when 'county'
          (2..sheet.last_row).each do |i|
            result[sheet.cell(i, 4)] << { 'county_name' => sheet.cell(i, 2) }
          end
        when 'zipcode'
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

      def import_records(data, year, import_timestamp)
        state_abbreviation = EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
        geographic_rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item

        if geographic_rating_area_model == 'single'
          ::BenefitMarkets::Locations::RatingArea.find_or_create_by!({
                                                                       active_year: year,
                                                                       exchange_provided_code: "R-#{state_abbreviation}001",
                                                                       county_zip_ids: [],
                                                                       covered_states: [state_abbreviation]
                                                                     })
          return Success("Created Rating areas")
        end

        data.each do |rating_area_id, locations|

          location_ids = locations.map do |loc_record|
            query_criteria = {
              state: state_abbreviation,
              county_name: loc_record['county_name']
            }

            case geographic_rating_area_model
            when 'county'
              query_criteria.merge!({ county_name: loc_record['county_name'].squish! })
            when 'zipcode'
              query_criteria.merge!({ zip: loc_record["zip"].squish! })
            else
              query_criteria.merge!({ county_name: loc_record['county_name'].squish!, zip: loc_record["zip"].squish! })
            end

            county_zip = ::BenefitMarkets::Locations::CountyZip.where(query_criteria).first
            county_zip._id
          end

          rating_area = ::BenefitMarkets::Locations::RatingArea.where({active_year: year, exchange_provided_code: rating_area_id }).first

          if rating_area.present?
            rating_area.county_zip_ids = location_ids
            rating_area.save!
          else
            ::BenefitMarkets::Locations::RatingArea.new(
              {
                created_at: import_timestamp,
                active_year: year,
                exchange_provided_code: rating_area_id,
                county_zip_ids: location_ids
              }
            ).save!
          end
        rescue StandardError => e
          return Failure({errors: ["Unable to import Rating Areas from file. Error while parsing #{rating_area_id} - #{locations} with error #{e}"]})
        end
        Success('Created Rating Areas for given data')
      end
    end
  end
end
