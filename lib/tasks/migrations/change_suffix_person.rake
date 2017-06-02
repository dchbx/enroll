require File.join(Rails.root, "app", "data_migrations", "change_suffix_person")
# This rake task is to change the name suffix of a person
# RAILS_ENV=production bundle exec rake migrations:change_suffix_person hbx_ids='19760877 19776645 19747772 19758664 19776417 18941825 19766429 19761376 19753221 19762647 19775694 19757825 19749172 19772583 19771579 19745475 19744827 19761611 19763400 19773230 19743457 2085463 19753992 2166772 19771972 19756452 19771773 19759229 19753432 19760652 18942772 19759405 19771826 19743273' 
namespace :migrations do
  desc "changing person suffix"
  ChangeSuffixPerson.define_task :change_suffix_person => :environment
end