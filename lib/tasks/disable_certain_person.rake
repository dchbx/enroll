namespace :person do
  desc "update status for person Jennefer Louise Rivera"
  task :disable_wrong_person => :environment do
    actived_hbxs = ["19789530"]
    disabled_hbxs = ["19789529", "19894827"]

    actived_hbxs.each do |hbx|
      Person.by_hbx_id(hbx).entries.each do |people|
        people.update(is_active: true) unless people.is_active
        puts "person with hbx_id(#{people.hbx_id}) is active."
      end
    end

    disabled_hbxs.each do |hbx|
      Person.by_hbx_id(hbx).entries.each do |people|
        people.update(is_active: false) if people.is_active
        puts "person with hbx_id(#{people.hbx_id}) is not active."
      end
    end
  end
end
