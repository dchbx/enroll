def load_irs_families_seed
    if File.exists?("db/seedfiles/irs_groups.csv")
      member_ids = {}
      family_mappings = {}
      CSV.foreach("db/seedfiles/irs_groups.csv", :headers => true) do |row|
        rec = row.to_hash
        m_id = row['hbx_id']
        family_mappings[m_id] = rec
      end
      member_ids_records = Person.collection.aggregate([{
       "$project" => { "hbx_id" => 1 }
      }])
      member_ids_records.each do |m_id_rec|
        member_ids[m_id_rec['hbx_id']] = m_id_rec['_id'].to_s
      end
      family_props_mappings = {}
      family_mappings.each_pair do |k, v|
        mapped_person = member_ids[k]
        if !mapped_person.nil?
          family_props_mappings[mapped_person] = v
        end
      end
      primary_applicant_list = Family.collection.raw_aggregate([
        {"$unwind" => "$family_members"},
        {"$match" => {"family_members.is_primary_applicant" => true}},
        {"$project" => {"_id" => "$family_members.person_id"}}
      ]).map { |r| r['_id'].to_s }
      miss_rate = primary_applicant_list - family_props_mappings.keys
      puts miss_rate.first
      puts miss_rate.length
      all_families = ::Family.unscoped.all
      total_families = all_families.count
      puts "Processing #{total_families} families for irs groups"
      chunk_number = 50
      chunk = total_families.to_f/(chunk_number.to_f)
      milestone = chunk
      all_families.each_with_index do |fam, idx|
        pa_id = fam.primary_applicant.person_id.to_s
        if family_props_mappings.has_key?(pa_id)
          changed_rec = false
          family_props = family_props_mappings[pa_id]
          irs_group = fam.irs_groups.first
          new_group_number = family_props['irs_group_id']
          if irs_group.hbx_assigned_id != new_group_number
            irs_group.hbx_assigned_id = new_group_number
            irs_group.touch
            fam.touch
            changed_rec = true
          end
          new_e_case_id = family_props['e_case_id']
          if fam.e_case_id != new_e_case_id
            fam.e_case_id = new_e_case_id
            changed_rec = true
          end
          if changed_rec
            fam.save!
          end
        end
        if idx > milestone
          milestone = milestone + chunk
          puts idx 
          current_value = ((idx.to_f/total_families.to_f) * 100.00).round
          puts "Loaded #{current_value}% of families"
        end
      end
    end
end


namespace :seed do
  desc "Load the people data"
  task :people => :environment do
    Person.delete_all
    file = File.open("db/seedfiles/people.json", "r")
    contents = file.read
    file.close
    data = JSON.load(contents)
    puts "Loading #{data.count} people."
    num_success = data.reduce(0) do |acc, pd|
      begin
      person = Person.create!(pd)
      rescue
        raise pd.inspect
      end
      person.valid? ? acc + 1 : acc
    end
    puts "Loaded #{num_success} people successfully."
  end

  desc "Load the family data"
  task :families => :environment do
    Family.delete_all
    if File.exists?("db/seedfiles/heads_of_families.json")
      puts "Loading families"
      file = File.open("db/seedfiles/heads_of_families.json")
      heads_of_family = JSON.load(file.read)
      file.close
      puts "Loading #{heads_of_family.length} families"
      families_built = 0
      total_families = heads_of_family.length
      chunk_number = 20
      chunk = total_families.to_f/(chunk_number.to_f)
      milestone = chunk
      Person.each do |person|
        if heads_of_family.include?(person.id.to_s)
          Family.new.build_from_person(person).save!
          families_built = families_built + 1
          if families_built > milestone
            milestone = milestone + chunk
            current_value = ((families_built.to_f/total_families.to_f) * 100.00).round
            puts "Loaded #{current_value}% of families"
          end
        end
      end
      puts "Loaded #{families_built} families successfully"
    end
    load_irs_families_seed
  end
end