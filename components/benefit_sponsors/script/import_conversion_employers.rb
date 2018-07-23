# Used to load conversion employer through script
#
# @return nil if data imported and put the results in conversion_employer_results file
# @raise exception if file is not excel or csv or error raised during data import
module BenefitSponsors
  class ConversionEmployers

    def import_employer(in_file)
      begin
        config = YAML.load_file("#{Rails.root}/conversions.yml")
        result_file = File.open(File.join(Rails.root, "conversion_employer_results", "RESULT_" + File.basename(in_file) + ".csv"), 'wb')

        # get site key from new model
        unless Settings.site.key == :mhc
          importer = BenefitSponsors::Importers::Mhc::ConversionEmployerSet.new(in_file, result_file, config["conversions"]["employer_profile_date"])
        else
          importer = ::Importers::ConversionEmployerSet.new(in_file, result_file, config["conversions"]["employer_profile_date"])
        end

        importer.import!
        result_file.close
        puts "***" * 8 unless Rails.env.test?
        puts "Placed the results under folder conversion_employer_results" unless Rails.env.test?

      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
      end
    end
  end
end

dir_glob = File.join(Rails.root, "conversion_employers", "*.{xlsx,csv}")

Dir.glob(dir_glob).sort.each do |file|
  puts "started processing the file : #{file}"
  conversion_object = BenefitSponsors::ConversionEmployers.new
  conversion_object.import_employer(file)
end
