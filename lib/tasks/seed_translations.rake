namespace :seed do
  ###################################################################################
  #
  # NOTE:  To call this rake task, use this syntax:
  #
  #     rake seed:translations["db/seedfiles/english_translations_seed.rb"]
  #
  # You might have to escape the square brackets like this, if you are using zsh:
  #
  #     rake seed:translations\["db/seedfiles/english_translations_seed.rb"\]
  #
  ###################################################################################
  desc "load translations from the specified file"
  task :translations, [:file] => [:environment] do |t, args|
    puts "Seeding #{args[:file]}"
    require File.join(Rails.root, args[:file][0..-4])
  end
end
