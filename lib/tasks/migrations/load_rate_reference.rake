namespace :load_rate_reference do
  desc "load rating regions from xlsx file"
  task :update_rating_areas => :environment do
    begin
      file_path = File.join(Rails.root, 'db/seedfiles/plan_xmls', Settings.aca.state_abbreviation.downcase, 'xls_templates', "SHOP_ZipCode_CY2017_FINAL.xlsx")
      puts "processing file : #{file_path}"
      xlsx = Roo::Spreadsheet.open(file_path)
      sheet = xlsx.sheet(0)
      (2..sheet.last_row).each do |i|
        RatingArea.find_or_create_by!(
            zip_code: sheet.cell(i,1),
            county_name: sheet.cell(i,2),
            zip_code_in_multiple_counties: to_boolean(sheet.cell(i,3)),
            rating_area: sheet.cell(i,4)
            )
      end
    rescue => e
      puts e.inspect
    end
  end


  def to_boolean(value)
    return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
    return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{value}\"")
  end
end
