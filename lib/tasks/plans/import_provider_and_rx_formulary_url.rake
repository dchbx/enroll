# This rake task imports provider and rxformulary urls into 2016 plans from master xlsx file.
# Dev note: Some rx formulary urls in the master xlsx file does not have http in the urls,
#           which is causing a routing issue as the rx formulary urls without http are getting appended
#           to the current url. (Ex: http://localhost:3000/plans/plan_id/www.carrier_name.com)
#           So including http at the start of each rx formulary urls that does not have http.

namespace :import do
  task :provider_and_rx_formulary_url => :environment do
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "**", "*.xlsx"))
    files.each do |file|
      year = file.split("/")[-2].to_i
      puts "*"*80
      puts "Importing provider and formulary url's from #{file}..."
      if file.present?
        result = Roo::Spreadsheet.open(file)
        sheets = ["IVL", "SHOP Q1", "Dental SHOP"]
        sheets << "IVL Dental" if year > 2016
        sheets.each do |sheet_name|
          sheet_data = if year == 2017
            if sheet_name == "IVL"
              result.sheet(0)
            elsif sheet_name == "SHOP Q1"
              result.sheet(4)
            else
              result.sheet(sheet_name)
            end
          else
            result.sheet(sheet_name)
          end

          @header_row = sheet_data.row(1)
          assign_headers

          last_row = sheet_data.last_row
          (2..last_row).each do |row_number| # data starts from row 2, row 1 has headers
            row_info = sheet_data.row(row_number)
            hios_id = row_info[@headers["hios/standard component id"]].squish
            provider_directory_url = row_info[@headers["provider directory url"] || @headers["provider network url"]]
            plans = Plan.where(hios_id: /#{hios_id}/, active_year: year)
            plans.each do |plan|
              plan.provider_directory_url = provider_directory_url
              if !["Dental SHOP", "IVL Dental"].include?(sheet_name)
                rx_formulary_url = row_info[@headers["rx formulary url"]]
                plan.rx_formulary_url =  rx_formulary_url.include?("http") ? rx_formulary_url : "http://#{rx_formulary_url}"
              end
              plan.save
            end
          end
        end
      end
    end
    puts "*"*80
    puts "import complete"
    puts "*"*80
  end

  def assign_headers
    @headers = Hash.new
    @header_row.each_with_index {|header,i|
      @headers[header.to_s.underscore] = i
    }
    @headers
  end
end