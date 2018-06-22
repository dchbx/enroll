require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCuramUserRecords < MongoidMigrationTask
  def migrate
    puts "Should be used ONLY when confirmed that an user in IAM is already been removed" unless Rails.env.test?

    begin
      action = ENV['action'].to_s
      email = ENV['user_email']
      user_name = ENV['user_name'].to_s
      find_user_by = ENV['find_user_by']
      record = case find_user_by
               when 'email'
                 CuramUser.where(email: email).first
               when 'user_name'
                 CuramUser.where(username: user_name).first
               else
                 raise StandardError.new('Invalid param')
               end
      if action.blank?
        puts "Please give input. Check your query" unless Rails.env.test?
        return
      end
      if action.casecmp("update_username") == 0
        update_username(record)
      elsif action.casecmp("update_email") == 0
        update_email(record)
      end
    rescue => e
      puts "#{e.message}"
    end
  end

  private

  def update_username(user)
    if ENV['new_user_name'].present?
      user.update_attributes!(username: ENV['new_user_name'].to_s)
      puts "Succesfully updated username" unless Rails.env.test?
    else
      puts "new_user_name not found" unless Rails.env.test?
    end
  end

  def update_email(user)
    if ENV['new_user_email'].present?
      user.update_attributes!(email: ENV['new_user_email'].to_s)
      puts "Succesfully updated email" unless Rails.env.test?
    else
      puts "new_user_email not found" unless Rails.env.test?
    end
  end
end
