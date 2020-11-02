namespace :load_service_reference do

  task :run_all_service_areas => :environment do
    if Settings.site.key.to_s == "dc"
      Rake::Task['load_service_reference:dc_service_areas'].invoke
    else
      files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{Settings.aca.state_abbreviation.downcase}/xls_templates/service_areas", "**", "*.xlsx"))
      puts "*"*80 unless Rails.env.test?
      # CarrierServiceArea.delete_all # delete and recreate all carrier service areas.
      files.sort.each do |file|
        puts "processing file #{file}" unless Rails.env.test?
        # old model
        Rake::Task['load_service_reference:update_service_areas'].invoke(file)
        Rake::Task['load_service_reference:update_service_areas'].reenable
        # end old model

        # new model
        Rake::Task['load_service_reference:update_service_areas_new_model'].invoke(file)
        Rake::Task['load_service_reference:update_service_areas_new_model'].reenable
        # end new model
      end
      puts "created #{CarrierServiceArea.all.size} service areas in old model" unless Rails.env.test?
      puts "*"*80 unless Rails.env.test?
    end
  end

  # will only create if the service areas are not present.
  desc "dc service areas"
  task :dc_service_areas, [:active_year] => :environment do |t, args|
    if Settings.site.key.to_s == "dc"
      years = args[:active_year].present? ? [args[:active_year].to_i] : (2014..2021)
      years.each do |year|
        puts "Creating Service areas for new model #{year}" unless Rails.env.test?
        ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |issuer_organization|
          issuer_profile = issuer_organization.issuer_profile
          ::BenefitMarkets::Locations::ServiceArea.find_or_create_by!({
             active_year: year,
             issuer_provided_code: "DCS001",
             covered_states: ["DC"],
             county_zip_ids: [],
             issuer_profile_id: issuer_profile.id,
             issuer_hios_id: nil,
             issuer_provided_title: issuer_profile.legal_name}
          )
        end
      end
    end
  end

  task :update_service_areas_new_model, [:file] => :environment do |t,args|
    row_data_begin = 13
    @issuer_profile_hash = {}
    set_issuer_profile_hash
    total = 0
    begin
      file = args[:file]
      @year = file.split("/")[-2].to_i

      xlsx = Roo::Spreadsheet.open(file)
      sheet = xlsx.sheet(0)
      issuer_hios_id = sheet.cell(6,2).to_i.to_s
      (row_data_begin..sheet.last_row).each do |i|
        serves_entire_state = to_boolean(sheet.cell(i,3))
        serves_partial_county = to_boolean(to_boolean(sheet.cell(i,5)))
        if serves_entire_state
          sa = ::BenefitMarkets::Locations::ServiceArea.where(
            active_year: @year,
            issuer_provided_code: sheet.cell(i,1),
            covered_states: ["MA"],
            issuer_profile_id: @issuer_profile_hash[issuer_hios_id],
            issuer_provided_title: sheet.cell(i,2)
          ).first
          if sa.present?
            sa.issuer_hios_id = issuer_hios_id
            sa.save
          else
            ::BenefitMarkets::Locations::ServiceArea.create(
              active_year: @year,
              issuer_provided_code: sheet.cell(i,1),
              covered_states: ["MA"],
              issuer_hios_id: issuer_hios_id,
              issuer_profile_id: @issuer_profile_hash[issuer_hios_id],
              issuer_provided_title: sheet.cell(i,2)
            )
          end
        elsif serves_entire_state == false
          existing_state_wide_areas = ::BenefitMarkets::Locations::ServiceArea.where(
            active_year: @year,
            issuer_provided_code: sheet.cell(i,1),
            issuer_profile_id: @issuer_profile_hash[issuer_hios_id],
            # issuer_hios_id: issuer_hios_id,
            # covered_states: nil
          )
          if existing_state_wide_areas.count > 0 && existing_state_wide_areas.first.covered_states.present? && existing_state_wide_areas.first.covered_states.include?("MA")
            v = existing_state_wide_areas.first
            v.issuer_hios_id = issuer_hios_id
            v.save
          else

            county_name, state_code, county_code = extract_county_name_state_and_county_codes(sheet.cell(i,4))

            records = ::BenefitMarkets::Locations::CountyZip.where({county_name: county_name})

            if sheet.cell(i,6).present?
              extracted_zips = extracted_zip_codes(sheet.cell(i,6)).each {|t| t.squish!}
              records = records.where(:zip.in => extracted_zips)
            end

            location_ids = records.map(&:_id).uniq.compact

            if existing_state_wide_areas.count > 0
              v = existing_state_wide_areas.first
              v.county_zip_ids << location_ids
              v.county_zip_ids = v.county_zip_ids.flatten.uniq
              v.issuer_hios_id = issuer_hios_id
              v.save
            else
              ::BenefitMarkets::Locations::ServiceArea.create({
                active_year: @year,
                issuer_provided_code: sheet.cell(i,1),
                issuer_profile_id: @issuer_profile_hash[issuer_hios_id],
                issuer_hios_id: issuer_hios_id,
                issuer_provided_title: sheet.cell(i,2),
                county_zip_ids: location_ids
              })
            end
          end

        end
      end

    rescue => e
      puts e.inspect unless Rails.env.test?
      puts " --------- " unless Rails.env.test?
      puts e.backtrace unless Rails.env.test?
    end

  end

  desc "load service regions from xlsx file"
  task :update_service_areas, [:file] => :environment do |t,args|
    row_data_begin = 13
    count = 0
    begin
      file = args[:file]
      @year = file.split("/")[-2].to_i

      xlsx = Roo::Spreadsheet.open(file)
      sheet = xlsx.sheet(0)
      hios_id = sheet.cell(6,2).to_i
      (row_data_begin..sheet.last_row).each do |i|
        serves_entire_state = to_boolean(sheet.cell(i,3))
        serves_partial_county = to_boolean(to_boolean(sheet.cell(i,5)))

        if serves_entire_state
          csa = CarrierServiceArea.where(
            active_year: @year,
            issuer_hios_id: hios_id,
            service_area_id: sheet.cell(i,1),
            service_area_name: sheet.cell(i,2),
            serves_entire_state: true
          ).first
          if csa.present?
          else
            CarrierServiceArea.create!(
              active_year: @year,
              issuer_hios_id: hios_id,
              service_area_id: sheet.cell(i,1),
              service_area_name: sheet.cell(i,2),
              serves_entire_state: true,
              county_name: nil,
              county_code: nil,
              state_code: nil,
              service_area_zipcode: nil,
              partial_county_justification: nil
            )
            count = count + 1
          end
        elsif serves_partial_county
          county_name, state_code, county_code = extract_county_name_state_and_county_codes(sheet.cell(i,4))
          extracted_zip_codes(sheet.cell(i,6)).each do |zip|
            csa_1 = CarrierServiceArea.where(
              active_year: @year,
              issuer_hios_id: hios_id,
              service_area_id: sheet.cell(i,1),
              service_area_name: sheet.cell(i,2),
              serves_entire_state: false,
              county_name: county_name,
              county_code: county_code,
              state_code: state_code,
              service_area_zipcode: zip,
              partial_county_justification: sheet.cell(i,7)
            ).first
            if csa_1.present?
            else
              CarrierServiceArea.create!(
                active_year: @year,
                issuer_hios_id: hios_id,
                service_area_id: sheet.cell(i,1),
                service_area_name: sheet.cell(i,2),
                serves_entire_state: false,
                county_name: county_name,
                county_code: county_code,
                state_code: state_code,
                service_area_zipcode: zip,
                partial_county_justification: sheet.cell(i,7)
              )
              count = count + 1
            end
          end
        else
          county_name, state_code, county_code = extract_county_name_state_and_county_codes(sheet.cell(i,4))
          RatingArea.find_zip_codes_for(county_name: county_name).each do |zip|
            csa_2 = CarrierServiceArea.where(
              active_year: @year,
              issuer_hios_id: hios_id,
              service_area_id: sheet.cell(i,1),
              service_area_name: sheet.cell(i,2),
              serves_entire_state: false,
              county_name: county_name,
              county_code: county_code,
              state_code: state_code,
              service_area_zipcode: zip,
              partial_county_justification: nil
            ).first
            if csa_2.present?
            else
              CarrierServiceArea.create!(
                active_year: @year,
                issuer_hios_id: hios_id,
                service_area_id: sheet.cell(i,1),
                service_area_name: sheet.cell(i,2),
                serves_entire_state: false,
                county_name: county_name,
                county_code: county_code,
                state_code: state_code,
                service_area_zipcode: zip,
                partial_county_justification: nil
              )
              count = count + 1
            end
          end
        end
      end
    rescue => e
      puts e.inspect unless Rails.env.test?
      puts " --------- " unless Rails.env.test?
      puts e.backtrace unless Rails.env.test?
    end

  end

  private

  def set_issuer_profile_hash
    exempt_organizations = ::BenefitSponsors::Organizations::Organization.issuer_profiles
    exempt_organizations.each do |exempt_organization|
      issuer_profile = exempt_organization.issuer_profile
      issuer_profile.issuer_hios_ids.each do |issuer_hios_id|
        @issuer_profile_hash[issuer_hios_id] = issuer_profile.id.to_s
      end
    end
    @issuer_profile_hash
  end

  def to_boolean(value)
    return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
    return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)
    return nil
  end

  def extracted_zip_codes(column)
    column.present? && column.split(/\s*,\s*/)
  end

  def extract_county_name_state_and_county_codes(county_field)
    begin
      county_name, state_and_county_code = county_field.split(' - ')
      [county_name, state_and_county_code[0..1], state_and_county_code[2..state_and_county_code.length]]
    rescue => e
      puts county_field
      puts e.inspect
      return ['undefined',nil,nil]
    end
  end

end
