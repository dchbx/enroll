def import_employee(in_file)
#  begin
    result_file = File.open(File.join(Rails.root, "conversion_employee_policy_results", "RESULT_" + File.basename(in_file) + ".csv"), 'wb')
    importer = Importers::ConversionEmployeePolicySet.new(in_file, result_file, Date.new(2016,12,1), 2016)
    importer.import!
    result_file.close
#  rescue
#    raise in_file.inspect
#  end
end

dir_glob = File.join(Rails.root, "conversion_employees", "*.{xlsx,csv}")
Dir.glob(dir_glob).each do |file|
  import_employee(file)
end
