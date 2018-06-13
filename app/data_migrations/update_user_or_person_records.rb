require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateUserOrPersonRecords < MongoidMigrationTask
  def migrate
    begin
      action = ENV['action'].to_s
      email = ENV['user_email'] || ENV['person_email'].to_s
      user_name = ENV['user_name'].to_s
      headless_user = ENV['headless_user'].to_s
      find_user_by = ENV['find_user_by'] || ENV['hbx_id'].to_s
      dob = Date.strptime(ENV['dob'].to_s, "%d/%m/%Y") if ENV['dob'].present?

      record = case find_user_by
               when "email"
                 find_user_from_email(email)
               when "#{ENV['hbx_id']}"
                 find_person(find_user_by)
               else
                 find_user_by_user_name(user_name)
               end


      if record.size != 1
        puts "No user record (or) found more than 1 user record with e-mail/username you entered" unless Rails.env.test?
        return
      end

      if action.blank? && headless_user.casecmp("yes") != 0
        puts "Please give input. Check your query" unless Rails.env.test?
        return
      end

      if action.casecmp("update_username") == 0
        user = record.first.user
        update_oim_id(user, user_name) if user
      end

      if action.casecmp("update_email") == 0
        update_email(record.first, email)
      end

      if action.casecmp("update_person_home_email") == 0
        update_person_home_email(record.first, email)
      end

      if action.casecmp("update_person_work_email") == 0
        update_person_work_email(record.first, email)
      end

      if action.casecmp("person_dob") == 0
        update_person_dob(record.first, dob)
      end

      if headless_user.casecmp("yes") == 0
        handle_headless_user(record.first)
      end

    rescue => e
      puts "#{e}"
    end
  end

  def find_user_from_email(email)
    User.where(email: email)
  end

  def find_person(hbx_id)
    Person.where(hbx_id: hbx_id)
  end

  def find_user_by_user_name(user_name)
    User.where(oim_id: user_name)
  end

  def update_oim_id(user, user_name)
    user = user.user if user.class == Person
    ENV['new_user_name'].present? ? user.update_attributes!(oim_id: ENV['new_user_name'].to_s) : user.update_attributes!(oim_id: user_name)
    puts "Successfully updated username with #{user.oim_id}" unless Rails.env.test?
  end

  def update_email(user, email)
    user = user.user if user.class == Person
    ENV['new_user_email'].present? ? user.update_attributes!(email: ENV['new_user_email'].to_s) : user.update_attributes!(email: email)
    puts "Successfully updated email with #{user.email}" unless Rails.env.test?
  end

  def update_person_home_email(person, address)
    person = person.person if person.class == User
    email = person.emails.detect { |email| email.kind == "home"}
    if email.blank?
      create_email(__method__.to_s.split('_')[2], address, person)
    else
      email.update_attributes!(address: address)
      puts "Updated Home E-mail address on person record" unless Rails.env.test?
    end
  end

  def update_person_work_email(person, address)
    person = person.person if person.class == User
    email = person.emails.detect { |email| email.kind == "work"}
    if email.blank?
      create_email(__method__.to_s.split('_')[2], address, person)
    else
      email.update_attributes!(address: address)
      puts "Updated Work E-mail address on person record" unless Rails.env.test?
    end
  end

  def update_person_dob(person, dob)
    person = person.person if person.class == User
    if TimeKeeper.date_of_record - 110.years > dob
      puts "No kidding!! seriously more than 110 years old!!" unless Rails.env.test?
      return
    end

    if person.employee_roles.present?
      puts "This person was already linked on roster. Check the Census Record. Attempt Failed!!" unless Rails.env.test?
      return
    end

    attrs = {:ssn => person.ssn, dob: dob, last_name: person.last_name, first_name: person.first_name }

    if Person.match_by_id_info(attrs).size > 0
      puts "This may effect the person match!! Assign this ticket to Dev" unless Rails.env.test?
      return
    else
      person.update_attributes!(dob: dob)
      puts "Succesfully updated dob on person record" unless Rails.env.test?
    end
  end

  def handle_headless_user(user)
    if user.person.blank?
      user.destroy!
      puts "Succesfully destroyed headless user record" unless Rails.env.test?
    else
      puts "This is not a headless user" unless Rails.env.test?
    end
  end

  def create_email(kind, address, person)
    puts "No Existing #{kind.capitalize} Email Record Found. Do you want to create a new #{kind.capitalize} Email?(y/n)" unless Rails.env.test?
    result = STDIN.gets.chomp();
    if result == "yes" || result == "y"
      person.emails << Email.new(kind: kind, address: address)
      person.save!
      puts "Succesfully created #{kind.capitalize} Email" unless Rails.env.test?
    else
      "You selected not to create a new #{kind.capitalize} Email" unless Rails.env.test?
    end
  end
end
