require 'csv'

def create_directory(path)
  if Dir.exists?(path)
    FileUtils.rm_rf(path)
  end
  Dir.mkdir path
end

create_directory "#{Rails.root.to_s}/public/DCEXCHANGE_#{TimeKeeper.date_of_record.strftime("%Y%m%d")}_SHOPCR/"

count = 0
CSV.foreach("ConversionMailing7_28_16.csv", headers: :true) do |row|
  data_row = row.to_hash
  notice_builder = ShopNotices::ConversionEmployerRenewalNotice.new(data_row)
  notice_builder.deliver
  count += 1
  if count > 10
    break
  end
end