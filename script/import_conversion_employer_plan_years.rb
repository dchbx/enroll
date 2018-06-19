def import_employer(in_file)
    config = YAML.load_file("#{Rails.root}/conversions.yml")
#  begin
    result_file = File.open(File.join(Rails.root, "conversion_employer_plan_year_results", "RESULT_PLAN_YEARS_" + File.basename(in_file) + ".csv"), 'wb')
    if Settings.site.key == :mhc
      importer = Importers::Mhc::ConversionEmployerPlanYearSet.new(in_file, result_file, config["conversions"]["plan_year_date"])
    else
      importer = Importers::ConversionEmployerPlanYearSet.new(in_file, result_file, config["conversions"]["plan_year_date"])
    end
    importer.import!
    result_file.close
#  rescue
#    raise in_file.inspect
#  end
end

dir_glob = File.join(Rails.root, "conversion_employer_plan_years", "*.{xlsx,csv}")
Dir.glob(dir_glob).sort.each do |file|
  puts "PROCESSING: #{file}"
  import_employer(file)
end
