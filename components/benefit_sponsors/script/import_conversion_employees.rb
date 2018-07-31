# Used to load conversion employer through script
#
# @return nil if data imported and put the results in conversion_employer_results file
# @raise exception if file is not excel or csv or error raised during data import
module BenefitSponsors
  class ConversionEmployees

    def import_employee(in_file)
      config = YAML.load_file("#{Rails.root}/conversions.yml")
      result_file = File.open(File.join(Rails.root, "conversion_employee_results", "RESULT_" + File.basename(in_file) + ".csv"), 'wb')

      unless Settings.site.key == :mhc
        importer = BenefitSponsors::Importers::Mhc::ConversionEmployeeSet.new(in_file, result_file, config["conversions"]["employee_date"], config["conversions"]["number_of_dependents"])
      else
        importer = Importers::ConversionEmployeeSet.new(in_file, result_file, config["conversions"]["employee_date"], config["conversions"]["number_of_dependents"])
      end
      importer.import!
      result_file.close

      puts "***" * 10 unless Rails.env.test?
      puts "Placed the results under folder conversion_employee_results" unless Rails.env.test?

    end
  end
end

dir_glob = File.join(Rails.root, "conversion_employees", "*.{xlsx,csv}")

Dir.glob(dir_glob).sort.each do |file|
  puts "started processing the file : #{file}"
  conversion_object = BenefitSponsors::ConversionEmployees.new
  conversion_object.import_employee(file)
end
