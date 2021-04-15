#rake products:load_county_zips([file_path])
#rake products:load_rating_areas([file_path, year])

namespace :products do

  desc "load county zip records"
  task :load_county_zips, [:file] => :environment do |t, args|
    puts ':::: Loading County Zips ::::'
    result = ::Operations::Products::ImportCountyZip.new.call({ file: args[:file], import_timestamp: DateTime.now })

    if result.success?
      puts ':::: Succesfully loaded county zip records ::::'
    else
      puts ":::: Loading County Zip records failed - #{result.failure} ::::"
    end
  end

  desc "load rating areas"
  task :load_rating_areas, [:file, :year] => :environment do |t, args|
    puts ':::: Loading County Zips ::::'
    result = ::Operations::Products::ImportRatingArea.new.call({ file: args[:file], year: args[:year], import_timestamp: DateTime.now })

    if result.success?
      puts ':::: Succesfully loaded rating area records ::::'
    else
      puts ":::: Loading Rating Area records failed - #{result.failure} ::::"
    end
  end
end
