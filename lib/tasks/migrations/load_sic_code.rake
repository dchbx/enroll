namespace :load_sic_code do
  desc "Load sic codes data"
  task :update_sic_codes => :environment do
    files = if Rails.env.test?
      Dir.glob(File.join(Rails.root, "spec/test_data/plan_data/sic_code/", "si_codes.xlsx"))
    else
      Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls", Settings.aca.state_abbreviation.downcase, "xls_templates", "si_codes.xlsx"))
    end
    puts "Creating SicCodes" unless Rails.env.test?
    if files.present?
      sheet_data = Roo::Spreadsheet.open(files.first)
      2.upto(sheet_data.last_row) do |row_number|
        begin
          row_data = sheet_data.row(row_number)
          sic_hash = {
            :division_code => row_data[1].sub('Division ', ''),
            :division_label => row_data[2],
            :major_group_code => row_data[4].sub('Major Group ',''),
            :major_group_label => row_data[5],
            :industry_group_code => row_data[7].sub('Industry Group ',''),
            :industry_group_label => row_data[8],
            :sic_code => row_data[10],
            :sic_label => row_data[11]
          }
          SicCode.create!(sic_hash)
        rescue Exception => e
          puts "#{e.message}"
        end
      end
    end
    puts "Successfully created #{SicCode.all.count} SicCode records." unless Rails.env.test?
  end
end
