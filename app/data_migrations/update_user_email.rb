require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateUserEmail < MongoidMigrationTask

  def migrate
    file_path = File.join(Rails.root, 'db', 'seedfiles', "update_user_email.xlsx") # path of excel file with email and oim_id data
    if File.exists?(file_path)
      result = Roo::Spreadsheet.open(file_path)
      2.upto(result.last_row) do |row_number|
        row_info = result.row(row_number)
        begin
          user = User.where(oim_id: /^#{row_info[0]}/i).first
          if user.present?
            user.email = row_info[1]
            user.save!
          else
            puts "Unable to find oim_id:#{row_info[0]}" unless Rails.env == 'test'
          end
        rescue => e
          puts "ERROR: #{row_info} Unable to update email" + e.message unless Rails.env == 'test'
        end
      end
    else
      puts "File not found " unless Rails.env == 'test'
    end
  end
end
