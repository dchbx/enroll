#rake load_rate_reference:run_all_rating_areas

namespace :load_rate_reference do

  task :run_all_rating_areas => :environment do
    if EnrollRegistry[:enroll_app].settings(:rating_areas).item == 'single'
      Rake::Task['load_rate_reference:dc_rating_areas'].invoke
    else
      files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase}/xls_templates/rating_areas", "**", "*.xlsx"))

      puts "*"*80 unless Rails.env.test?
      files.each do |file|
        puts "processing file #{file}" unless Rails.env.test?
        Rake::Task['load_rate_reference:update_rating_areas'].invoke(file)
        Rake::Task['load_rate_reference:update_rating_areas'].reenable
        puts "created #{RatingArea.all.size} rating areas in old model for all years" unless Rails.env.test?
        puts "created #{BenefitMarkets::Locations::RatingArea.all.size} rating areas in new model for all years" unless Rails.env.test?
      end
    end
    puts "*"*80 unless Rails.env.test?
  end

  # will only create if the rating areas are not present.
  desc "rating areas"
  task :dc_rating_areas, [:active_year] => :environment do |t, args|
    if EnrollRegistry[:enroll_app].settings(:rating_areas).item == 'single'
      years = args[:active_year].present? ? [args[:active_year].to_i] : (2014..2021)
      years.each do |year|
        puts "Creating DC Rating areas for #{year}" unless Rails.env.test?
        ::BenefitMarkets::Locations::RatingArea.find_or_create_by!({
            active_year: year,
            exchange_provided_code: 'R-DC001',
            county_zip_ids: [],
            covered_states: ['DC']
        })
      end
    end
  end

  desc "load rating regions from xlsx file"
  task :update_rating_areas, [:file] => :environment do |t, args|
    begin
      file = args[:file]
      file_year = file.split("/")[-2].to_i
      xlsx = Roo::Spreadsheet.open(file)
      sheet = xlsx.sheet(0)

      # old model
      (2..sheet.last_row).each do |i|
        ra = RatingArea.find_or_create_by!(
            zip_code: sheet.cell(i, 1),
            county_name: sheet.cell(i, 2),
            zip_code_in_multiple_counties: to_boolean(sheet.cell(i, 3)),
            rating_area: sheet.cell(i, 4)
        )
      end
      # end of old model

      # new model
      @result_hash = Hash.new {|results, k| results[k] = []}

      (2..sheet.last_row).each do |i|
        @result_hash[sheet.cell(i, 4)] << {
            "county_name" => sheet.cell(i, 2),
            "zip" => sheet.cell(i, 1)
        }
      end

      @result_hash.each do |rating_area_id, locations|

        location_ids = locations.map do |loc_record|
          zip_code = loc_record['zip'].to_s.gsub('.0','')
          county_zip = ::BenefitMarkets::Locations::CountyZip.where({zip: zip_code,
                                                                     county_name: loc_record['county_name']}).first
          county_zip._id
        end

        ra = ::BenefitMarkets::Locations::RatingArea.where({active_year: file_year,
                                                            exchange_provided_code: rating_area_id}).first


        if ra.present?
          ra.county_zip_ids = location_ids
          ra.save
        else
          ra = ::BenefitMarkets::Locations::RatingArea.create({active_year: file_year,
                                                               exchange_provided_code: rating_area_id,
                                                               county_zip_ids: location_ids})
        end
      end
        # end of new model
    rescue => e
      puts e.inspect
    end
  end

  def to_boolean(value)
    return true if value == true || value =~ (/(true|t|yes|y|1)$/i)
    return false if value == false || value =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{value}\"")
  end
end
