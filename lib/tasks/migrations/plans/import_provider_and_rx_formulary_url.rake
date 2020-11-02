# This rake task will do the following:
# 1. Mark plans as standard or not-standard(true/false)
# 2. Updates provider directory and rx formulary urls.
# 3. Updates network information(network notes) for plans
# Note: This rake task will be refactored in new model work.

# This rake task imports provider and rxformulary urls into 2016 plans from master xlsx file.
# Dev note: Some rx formulary urls in the master xlsx file does not have http in the urls,
#           which is causing a routing issue as the rx formulary urls without http are getting appended
#           to the current url. (Ex: http://localhost:3000/plans/plan_id/www.carrier_name.com)
#           So including http at the start of each rx formulary urls that does not have http.

namespace :import do
  task :common_data_from_master_xml, [:file] => :environment do |task, args|
    NATIONWIDE_NETWORK = ["Nationwide In-Network", "Nationwide"]
    DC_IN_NETWORK = ["DC Metro In-Network", "DC-Metro In-Network", "DC-Metro", "DC, MD (not available in VA)", "DC Metro"]
    files = Rails.env.test? ? [args[:file]] : Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{Settings.aca.state_abbreviation.downcase}/master_xml", "**", "*.xlsx"))

    if Settings.aca.state_abbreviation.downcase == "dc" # DC
      # TODO Fix Rake task for DC context and Spec.
      files.each do |file|
        year = file.split("/")[-2].to_i
        puts "*"*80 unless Rails.env.test?
        puts "Importing provider, formulary url's, network_data, standard_plan from #{file}..." unless Rails.env.test?
        if file.present?
          result = Roo::Spreadsheet.open(file)
          sheets =  if Rails.env.test?
                      result.sheets
                    else
                      ["IVL", "SHOP Q1", "Dental SHOP", "IVL Dental"]
                    end

          sheets.each do |sheet_name|
            next if result.sheets.exclude?(sheet_name)
            puts "processing sheet ::: #{sheet_name} :::" unless Rails.env.test?
            sheet_data = result.sheet(sheet_name)

            @header_row = sheet_data.row(1)
            assign_headers
            last_row = sheet_data.last_row
            (2..last_row).each do |row_number| # data starts from row 2, row 1 has headers
              row_info = sheet_data.row(row_number)
              hios_id = row_info[@headers["hios/standard component id"]].squish
              provider_directory_url = row_info[@headers["provider directory url"] || @headers["provider network url"]]
              plans = Plan.where(hios_id: /#{hios_id}/, active_year: year)
              plans.each do |plan|
                plan.name = row_info[@headers["plan name"]]
                plan.nationwide, plan.dc_in_network = [true, false] if NATIONWIDE_NETWORK.include?(row_info[@headers["network"]])
                plan.dc_in_network, plan.nationwide = [true, false] if DC_IN_NETWORK.include?(row_info[@headers["network"]])
                plan.provider_directory_url = provider_directory_url
                if !["Dental SHOP", "IVL Dental"].include?(sheet_name)
                  rx_formulary_url = row_info[@headers["rx formulary url"]]
                  plan.rx_formulary_url =  rx_formulary_url.include?("http") ? rx_formulary_url : "http://#{rx_formulary_url}"
                  if sheet_name == "IVL" && year > 2017
                    plan.is_standard_plan = row_info[@headers["standard plan?"]]
                  end
                end
                plan.save
              end

              products = ::BenefitMarkets::Products::Product.where(hios_id: /#{hios_id}/).select{|a| a.active_year == year}
              products.each do |product|
                product.title = row_info[@headers["plan name"]]
                product.nationwide, product.dc_in_network = [true, false] if NATIONWIDE_NETWORK.include?(row_info[@headers["network"]])
                product.dc_in_network, product.nationwide = [true, false] if DC_IN_NETWORK.include?(row_info[@headers["network"]])
                product.provider_directory_url = provider_directory_url
                if !["Dental SHOP", "IVL Dental"].include?(sheet_name)
                  rx_formulary_url = row_info[@headers["rx formulary url"]]
                  product.rx_formulary_url =  rx_formulary_url.include?("http") ? rx_formulary_url : "http://#{rx_formulary_url}"
                  if sheet_name == "IVL" && year > 2017
                    product.is_standard_plan = row_info[@headers["standard plan?"]]
                  end
                end
                product.save
              end
            end
          end
        end
      end
    else # MA
      files.each do |file|
      year = file.split("/")[-2].to_i
      puts "*"*80 unless Rails.env.test?
      puts "Importing provider and formulary url's, marking plans as standard and updating network information from #{file}..." unless Rails.env.test?
      if file.present?
        result = Roo::Spreadsheet.open(file)
        sheets = if year == 2017
          ["MA SHOP QHP"]
        elsif year == 2018
          ["2018_QHP", "2018_QDP"]
        elsif year == 2019
          ["2019_QHP", "2019_QDP"]
        end
        sheets.each do |sheet_name|
          sheet_data = result.sheet(sheet_name)

          @header_row = sheet_data.row(1)
          assign_headers

          last_row = sheet_data.last_row
          (2..last_row).each do |row_number| # data starts from row 2, row 1 has headers
            row_info = sheet_data.row(row_number)
            hios_id = row_info[@headers["hios/standard component id"]].squish
            provider_directory_url = row_info[@headers["provider directory url"]].strip

            # old model
            plans = Plan.where(hios_id: /#{hios_id}/, active_year: year)
            plans.each do |plan|
              plan.provider_directory_url = provider_directory_url
              if sheet_name != "#{year}_QDP"
                rx_formulary_url = row_info[@headers["rx formulary url"]].strip
                plan.rx_formulary_url =  rx_formulary_url.include?("http") ? rx_formulary_url : "http://#{rx_formulary_url}"
              end
              plan.is_standard_plan = row_info[@headers["standard plan?"]].strip == "Yes" ? true : false
              plan.network_information = row_info[@headers["network notes"]]
              plan.is_sole_source = row_info[@headers["sole source offering"]].strip == "Yes" ? true : false
              plan.is_horizontal = row_info[@headers["horizontal offering"]].strip == "Yes" ? true : false
              plan.is_vertical = row_info[@headers["vertical offerring"]].strip == "Yes" ? true : false
              plan.name = row_info[@headers["plan name"]].strip
              plan.save
            end
            # end of old model

            # new model
            product_package_kinds = []
            products = ::BenefitMarkets::Products::Product.where(hios_id: /#{hios_id}/).select{|a| a.active_year == year}
            products.each do |product|
              product.provider_directory_url = provider_directory_url
              if sheet_name != "#{year}_QDP"
                rx_formulary_url = row_info[@headers["rx formulary url"]].strip
                product.rx_formulary_url =  rx_formulary_url.include?("http") ? rx_formulary_url : "http://#{rx_formulary_url}"
              end
              product.is_standard_plan = row_info[@headers["standard plan?"]].strip == "Yes" ? true : false
              product.network_information = row_info[@headers["network notes"]]
              product.title = row_info[@headers["plan name"]].strip

              sole_source_offering = row_info[@headers["sole source offering"]].strip == "Yes" ? true : false
              horizontal_offering = row_info[@headers["horizontal offering"]].strip == "Yes" ? true : false
              vertical_offering = row_info[@headers["vertical offerring"]].strip == "Yes" ? true : false

              if product.product_kind.to_s == "health"
                if horizontal_offering == true
                  product_package_kinds << :metal_level
                end
                if vertical_offering == true
                  product_package_kinds << :single_issuer
                end
                if sole_source_offering == true
                  product_package_kinds << :single_product
                end
                product.product_package_kinds = product_package_kinds
              end

              product.save
            end
            # end of new model

          end
        end
      end
    end
    end
    puts "*"*80 unless Rails.env.test?
    puts "import complete" unless Rails.env.test?
    puts "*"*80 unless Rails.env.test?
  end

  def assign_headers
    @headers = Hash.new
    @header_row.each_with_index {|header,i|
      @headers[header.to_s.underscore.strip] = i
    }
    @headers
  end
end