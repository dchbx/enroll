def import_employer(in_file)
    config = YAML.load_file("#{Rails.root}/conversions.yml")
#  begin
    result_file = File.open(File.join(Rails.root, "conversion_employer_results", "RESULT_" + File.basename(in_file) + ".csv"), 'wb')
    if Settings.site.key == :mhc
      importer = Importers::Mhc::ConversionEmployerSet.new(in_file, result_file, config["conversions"]["employer_profile_date"])
    else
      importer = Importers::ConversionEmployerSet.new(in_file, result_file, config["conversions"]["employer_profile_date"])
    end

    importer.import!
    result_file.close
#  rescue
#    raise in_file.inspect
#  end
end

dir_glob = File.join(Rails.root, "conversion_employers", "*.{xlsx,csv}")
Dir.glob(dir_glob).sort.each do |file|
  puts "PROCESSING: #{file}"
  import_employer(file)
end
