require 'csv'
 
namespace :reports do
  namespace :language_preference do
    desc "List of all ivl's without english as their language_preference"
    task :language_preference_other_than_english_list => :environment do
      field_names = %w(
          First_Name
          Last_Name
          Language_Preference
        )
      count = 0
      file_name = "#{Rails.root}/public/language_preference_other_than_english_list.csv"
 
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        persons= []
        Person.each do |person|
          persons << person if person.consumer_role.present? && person.consumer_role.language_preference != "English"
        end
        persons.each do |person|
          csv << [
            person.first_name,
            person.last_name,
            person.consumer_role.language_preference
          ]
          count += 1
        end
      end
      puts "Total ivl's with language preference other than english count is #{count}"
    end
  end
end
