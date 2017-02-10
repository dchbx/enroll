def import_employer(in_file)
#  begin
    result_file = File.open(File.join(Rails.root, "conversion_employer_plan_year_results", "RESULT_PLAN_YEARS_" + File.basename(in_file) + ".csv"), 'wb')
    importer = Importers::ConversionEmployerPlanYearSet.new(in_file, result_file, Date.new(2016,3,1))
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
