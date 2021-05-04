# frozen_string_literal: true

module Operations
  module Products
    # This class is to load service areas.
    class ImportServiceArea
      include Dry::Monads[:result, :do]

      def call(params)
        values               = yield validate(params)
        issuer_profiles_hash = yield load_issuer_profiles
        sheet                = yield load_data(values[:file], values[:rating_area_model])
        _load                = yield import_records(sheet, values[:year], values[:row_data_begin], issuer_profiles_hash, values[:rating_area_model])
        Success()
      end

      private

      def validate(params)
        return Failure('Missing File') if params[:file].blank?
        return Failure('Missing Year') if params[:year].blank?
        return Failure('Missing Row data begins with') if params[:row_data_begin].blank?
        params.merge!(rating_area_model: EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item)
        Success(params)
      end

      def load_issuer_profiles
        exempt_organizations = ::BenefitSponsors::Organizations::Organization.issuer_profiles
        profiles_hash = exempt_organizations.inject({}) do |result, organization|
          issuer_profile = organization.issuer_profile
          issuer_profile.issuer_hios_ids.each do |issuer_hios_id|
            result[issuer_hios_id] = issuer_profile.id.to_s
          end
          result
        end
        Success(profiles_hash)
      end

      def load_data(file, rating_area_model)
        return Success() if rating_area_model == 'single'

        result = Roo::Spreadsheet.open(file)
        sheet = result.sheet(0)
        Success(sheet)
      end

      def import_records(sheet, year, row_data_begin, issuer_profile_hash, rating_area_model)
        state_abbreviation = EnrollRegistry[:enroll_app].setting(:state_abbreviation).item

        if rating_area_model == 'single'
          create_service_area_for_single_model(year, state_abbreviation)
          return Success("Created Service Areas")
        end

        issuer_hios_id = sheet.cell(6,2).to_i.to_s

        (row_data_begin..sheet.last_row).each do |i|
          serves_entire_state = to_boolean(sheet.cell(i,3))
          if serves_entire_state
            service_area = ::BenefitMarkets::Locations::ServiceArea.where(active_year: year, issuer_provided_code: sheet.cell(i,1), county_zip_ids: [],
                                                                          covered_states: [state_abbreviation], issuer_profile_id: issuer_profile_hash[issuer_hios_id], issuer_provided_title: sheet.cell(i,2)).first
            if service_area.present?
              service_area.update_attributes(issuer_hios_id: issuer_hios_id)
            else
              ::BenefitMarkets::Locations::ServiceArea.create(active_year: year, issuer_provided_code: sheet.cell(i,1), covered_states: [state_abbreviation], county_zip_ids: [],
                                                              issuer_hios_id: issuer_hios_id, issuer_profile_id: issuer_profile_hash[issuer_hios_id], issuer_provided_title: sheet.cell(i,2))
            end
          elsif serves_entire_state == false
            existing_state_wide_areas = ::BenefitMarkets::Locations::ServiceArea.where(
              active_year: year,
              issuer_provided_code: sheet.cell(i,1),
              issuer_hios_id: issuer_hios_id,
              covered_states: [state_abbreviation]
            )

            if existing_state_wide_areas.blank?
              county_name = extract_county_name(sheet.cell(i,4))
              query_criteria = load_query(rating_area_model, sheet.cell(i,6), county_name, state_abbreviation)

              records = ::BenefitMarkets::Locations::CountyZip.where(query_criteria)

              service_area = ::BenefitMarkets::Locations::ServiceArea.where(active_year: year, issuer_provided_code: sheet.cell(i,1),
                                                                            issuer_hios_id: issuer_hios_id, issuer_profile_id: issuer_profile_hash[issuer_hios_id]).first

              if service_area.blank?
                ::BenefitMarkets::Locations::ServiceArea.create!({ active_year: year, issuer_provided_code: sheet.cell(i,1), issuer_hios_id: issuer_hios_id,
                                                                   issuer_profile_id: issuer_profile_hash[issuer_hios_id], issuer_provided_title: sheet.cell(i,2), county_zip_ids: records.pluck(:_id)})
              else
                update_existing_service_area(service_area, sheet.cell(i,2), records.pluck(:_id))
              end
            end
          end
        rescue StandardError => e
          return Failure({errors: ["Unable to import service area from file. Error while parsing row #{i} with error #{e}"]})
        end
        Success('Created Rating Areas for given data')
      end

      def update_existing_service_area(service_area, issuer_provided_title, county_zip_ids)
        service_area.issuer_provided_title = issuer_provided_title
        service_area.county_zip_ids += county_zip_ids
        service_area.county_zip_ids.uniq!
        service_area.save!
      end

      def create_service_area_for_single_model(year, state_abbreviation)
        ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
          issuer_profile = issuer_organization.issuer_profile
          ::BenefitMarkets::Locations::ServiceArea.find_or_create_by!({
                                                                        active_year: year,
                                                                        issuer_provided_code: "#{state_abbreviation}S001",
                                                                        covered_states: [state_abbreviation],
                                                                        county_zip_ids: [],
                                                                        issuer_profile_id: issuer_profile.id,
                                                                        issuer_hios_id: nil,
                                                                        issuer_provided_title: issuer_profile.legal_name
                                                                      })
        end
      end

      def load_query(rating_area_model, column, county_name, abbr)
        extracted_zips = column.split(/\s*,\s*/).each(&:squish!) if column.present?

        query_criteria = { state: abbr }
        case rating_area_model
        when 'county'
          query_criteria.merge!({ county_name: county_name })
        when 'zipcode'
          query_criteria.merge!({ :zip.in => extracted_zips }) if extracted_zips.present?
        else
          if extracted_zips.present?
            query_criteria.merge!({ county_name: county_name, :zip.in => extracted_zips })
          else
            query_criteria.merge!({ county_name: county_name })
          end
        end
        query_criteria
      end

      def to_boolean(value)
        return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
        return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)
        nil
      end

      def extract_county_name(county_field)
        county_field.split(' - ')[0]
      rescue StandardError => e
        puts county_field
        puts e.inspect
        'undefined'
      end
    end
  end
end
