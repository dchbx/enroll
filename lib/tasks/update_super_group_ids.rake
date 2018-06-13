namespace :supergroup do
  desc "Migrating super group ID with macthing HIOS_Isuuer_Id"
  task :update_plan_id => :environment do
    files = if Rails.env.test?
      Dir.glob(File.join(Rails.root, "spec/test_data/plan_data/super_groups/", "**", "*.xlsx"))
    else
      Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{Settings.aca.state_abbreviation.downcase}/xls_templates/super_groups", "**", "*.xlsx"))
    end
    files.each do |file|
      puts "processing file #{file}" unless Rails.env.test?
      result = Roo::Spreadsheet.open(file)
      sheet_names = result.sheets
      sheet_names.each do |sheet_name|
        puts "processing sheet: #{sheet_name}" unless Rails.env.test?
        sheet_data = result.sheet(sheet_name)
        if sheet_data.last_row.present?
          @header_row = sheet_data.row(1)
          assign_headers
          2.upto(sheet_data.last_row) do |row_number|
            begin
              row_data = sheet_data.row(row_number)
              row_data[@headers["group_number"]] = row_data[@headers["group_number"]].to_i.to_s if sheet_name == "Altus"
              fetch_record = Plan.where(hios_id: row_data[@headers["hios_issuer_id"]], active_year: row_data[@headers["plan year"]]).first
              fetch_record.update_attributes(carrier_special_plan_identifier: row_data[@headers["group_number"]]) if fetch_record.present?
            rescue Exception => e
              puts "#{e.message}"
              puts "Raised Error because of #{$!.class}"
            end
          end
        end
      end
    end
  end

  def assign_headers
    @headers = Hash.new
    @header_row.each_with_index {|header,i|
      @headers[header.to_s.underscore] = i
    }
    @headers
  end
end
