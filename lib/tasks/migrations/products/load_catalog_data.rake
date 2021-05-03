#rake products:load_county_zips
#rake products:load_rating_areas[year]
#rake products:load_service_areas[year]

namespace :products do

  desc "load county zip records"
  task :load_county_zips => :environment do |t, args|
    puts ':::: Loading County Zips ::::'

    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase}/xls_templates/counties/#{TimeKeeper.date_of_record.year.to_s}", EnrollRegistry[:counties_import]&.item))

    files.each do |file|
      result = ::Operations::Products::ImportCountyZip.new.call({ file: file, import_timestamp: DateTime.now })

      if result.success?
        puts ':::: Succesfully loaded county zip records ::::'
      else
        puts ":::: Loading County Zip records failed - #{result.failure} ::::"
      end
    end
    puts ":::: Finished loading County Zips ::::"
  end

  desc "load rating areas"
  task :load_rating_areas, [:year] => :environment do |t, args|
    puts ':::: Loading Rating Areas ::::'

    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcasse}/xls_templates/rating_areas", "**", "*.xlsx"))

    files.each do |file|
      result = ::Operations::Products::ImportRatingArea.new.call({ file: file, year: args[:year], import_timestamp: DateTime.now })

      if result.success?
        puts ':::: Succesfully loaded rating area records ::::'
      else
        puts ":::: Loading Rating Area records failed - #{result.failure} ::::"
      end
    end

    puts ':::: Finished loading Rating Areas ::::'
  end

  desc "load Service areas"
  task :load_service_areas, [:year] => :environment do |t, args|
    puts ':::: Loading Service Areas ::::'

    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase}/xls_templates/service_areas", "**", "*.xlsx"))

    files.each do |file|
      result = ::Operations::Products::ImportServiceArea.new.call({ file: file, year: args[:year], row_data_begin: 13 })

      if result.success?
        puts ':::: Succesfully loaded Service area records ::::'
      else
        puts ":::: Loading Service Area records failed - #{result.failure} ::::"
      end
    end

    puts ':::: Finished loading Service Areas ::::'
  end
end
