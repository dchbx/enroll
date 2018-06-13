namespace :xml do
  task :standard_plans, [:file] => :environment do |task,args|
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/master_xml", "**", "*.xlsx"))
    files.each do |file|
      year = file.split("/")[-2].to_i

      puts "*"*80
      puts "Marking plans as standard or not-standard from #{file}..."
      if file.present?
        result = Roo::Spreadsheet.open(file)
        sheets = ["MA SHOP QHP"]
        sheets.each do |sheet_name|
          sheet_data = result.sheet(sheet_name)

          @header_row = sheet_data.row(1)
          assign_headers

          last_row = sheet_data.last_row
          (2..last_row).each do |row_number| # data starts from row 2, row 1 has headers
            row_info = sheet_data.row(row_number)
            hios_id = row_info[@headers["hios/standard component id"]].squish
            plans = Plan.where(hios_id: /#{hios_id}/, active_year: year)
            plans.each do |plan|
              plan.is_standard_plan = row_info[@headers["standard plan?"]] == "Yes" ? true : false
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