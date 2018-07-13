namespace :xml do
  task :network_info => :environment do
    NATIONWIDE_NETWORK = ["Nationwide In-Network"]
    DC_IN_NETWORK = ["DC Metro In-Network"]
    puts "*"*80
    puts "updating network info for carefirst shop plans"
    puts "*"*80
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", "**", "MASTER 2017 QHP_QDP Plan & Rate Matrix v.3.1.xlsx"))
    files.each do |file|
      result = Roo::Spreadsheet.open(file)
      sheet_data = result.sheet(10)
      last_row = sheet_data.last_row
      (2..last_row).each do |row_number|
        hios_id, network_data = sheet_data.row(row_number)
        plan = Plan.where(active_year: 2017, market: "shop", coverage_kind: "health", hios_id: /#{hios_id}/, csr_variant_id: "01").first
        if NATIONWIDE_NETWORK.include?(network_data)
          plan.nationwide, plan.dc_in_network = ["true", "false"]
        elsif DC_IN_NETWORK.include?(network_data)
          plan.nationwide, plan.dc_in_network = ["false", "true"]
        end
        plan.save
      end
    end
    puts "*"*80
    puts "import complete"
    puts "*"*80
  end

end