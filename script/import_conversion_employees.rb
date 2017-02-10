def import_employee(in_file)
#  begin
    result_file = File.open(File.join(Rails.root, "conversion_employee_results", "RESULT_" + File.basename(in_file) + ".csv"), 'wb')
    importer = Importers::ConversionEmployeeSet.new(in_file, result_file, Date.new(2016,12,1))
    importer.import!
    result_file.close
#  rescue
#    raise in_file.inspect
#  end
end

dir_glob = File.join(Rails.root, "conversion_employees", "*.{xlsx,csv}")
Dir.glob(dir_glob).sort.each do |file|
  puts "PROCESSING: #{file}"
  import_employee(file)
end
