def import_employee(in_file)
    config = YAML.load_file("#{Rails.root}/conversions.yml")
#  begin
    result_file = File.open(File.join(Rails.root, "conversion_employee_policy_results", "RESULT_" + File.basename(in_file) + ".csv"), 'wb')
    if Settings.site.key == :mhc
      importer = Importers::Mhc::ConversionEmployeePolicySet.new(in_file, result_file, config["conversions"]["employee_policies_date"], config["conversions"]["employee_policy_year"])
    else
      importer = Importers::ConversionEmployeePolicySet.new(in_file, result_file, config["conversions"]["employee_policies_date"], config["conversions"]["employee_policy_year"])
    end
    importer.import!
    result_file.close
#  rescue
#    raise in_file.inspect
#  end
end

dir_glob = File.join(Rails.root, "conversion_employees", "*.{xlsx,csv}")
Dir.glob(dir_glob).sort.each do |file|
  puts "PROCESSING...#{file}"
  import_employee(file)
end
