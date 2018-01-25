require 'csv'

namespace :user do
  desc "Check Existence of User with Given Email Address"
  task check_email_existence: :environment do
    csv_file_path="#{Rails.root}/#{ENV['csv_file_name']}"
    output_file_path="#{Rails.root}/check_email_existence_result_for_#{ENV['csv_file_name']}"
    file=File.open(output_file_path,'w')
    CSV.foreach(csv_file_path, headers: true, :encoding=>'utf-8') do |row|
      #user=User.where(email: "\"" + row.gsub("\n","\"") ).first
      user=User.where(email:row).first.try(:row)
      if user.present?
        file.puts "#{row},#{user.hbx_id},#{user.person.first_name},#{user.person.last_name}"
      else
        file.puts "#{row}"
      end
    end
    file.close
  end
end

