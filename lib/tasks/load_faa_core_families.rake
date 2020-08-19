namespace :seed do
  desc "Load financial assistances applications core families"
  task :faa_core_families => :environment do

    destroy_core_families = ENV["destroy_core_families"].to_s

    file_user = File.open("db/faa_core_seedfiles/core_faa_families.json", "r")
    contents_user = file_user.read
    file_user.close
    data_user = JSON.load(contents_user)
    puts "Loading #{data_user.count} people and their families for the core-29 scenarios"

    data_user.reduce(0) do |acc, ud|
      hashed_data = Hash[*ud.flatten]
      begin

        #destroy existing core family
        user_email = hashed_data["user"].first["email"]
        user_oim_id = hashed_data["user"].first["oim_id"]
        existing_user = User.all.where(email: user_email).and(oim_id: user_oim_id).first

        if existing_user.present?
          destroy_core_family(existing_user)
        end

        #create user record
        user = User.create!(hashed_data["user"])

        #create person record
        person = Person.new(hashed_data["person"].first)

        if !hashed_data["person"].first["no_ssn"].present?
          ssn = generate_ssn
          person.ssn = ssn
        end

        dob = generate_dob(hashed_data["person_age"])
        person.dob = dob
        person.update_attributes(user: user.first)
        person.save!

        #create consumer_role
        consumer_role = ConsumerRole.new(hashed_data["consumer_role"].first)
        consumer_role.update_attributes(person: person)
        if hashed_data["vlp_document"].first["id"].present?
          if hashed_data["vlp_document"].first.count >0
            vlp_documents = hashed_data["vlp_document"].first
            create_vlp_for_consumer_role(vlp_documents, person)
          end
        end
        consumer_role.save!

        #create family
        family = Family.new.build_from_person(person)
        family.save!

        #create dependent
        dependents_id = []
        dependents = hashed_data["dependents"].first

        dependents.each do |k, v|
          dependent = Person.create!(v.first["dependent"]).first
          dob = generate_dob(v.first["dependent_age"])
          dependent.dob = dob

          if !v.first["dependent"].first["no_ssn"].present?
            ssn = generate_ssn
            dependent.ssn = ssn
          end

          dependent.save!
          dependents_id << dependent.id

          if v.first["consumer_role"].present?
            consumer_role = ConsumerRole.new(v.first["consumer_role"].first)
            consumer_role.update_attributes(person: dependent)
            if v.first["vlp_document"].present?
              if v.first["vlp_document"].first.count >0
                vlp_documents = v.first["vlp_document"].first
                create_vlp_for_consumer_role(vlp_documents, dependent)
              end
            end
            consumer_role.save!
          end

          person.person_relationships.new(kind: v.first["kind"], relative_id: dependent.id, predecessor_id: dependent.id, successor_id: person.id, family_id: family.id)
          person.save!

          family.family_members.create!(person_id: dependent.id)
          family.relate_new_member(dependent, v.first["kind"])
          family.save!
        end

        #build matrix relationship between for all members
        if hashed_data["relation_ships"].first["rs1"].first["kind"].present?
          if hashed_data["relation_ships"].first.count >0
            count = hashed_data["relation_ships"].count
            while count!=0 do
              rs = hashed_data["relation_ships"][count-1]["rs#{count}"].first
              generate_relation(dependents_id[rs["predecessor"]-1], dependents_id[rs["successor"]-1], rs["kind"], family.id)
              count =count -1
            end
          end
        end
        family.reload
        family.build_relationship_matrix

        #create application in draft state
        application = family.applications.new
        application.populate_applicants_for(family)
        application.save!
        print "."
      rescue
        raise ud.inspect
      end
    end
    puts "loaded successfully"
  end
end

def generate_ssn
  ssn = 0
  count =0
  while count==0 do
    ssn = rand(999999999).to_s.center(9, rand(9).to_s).to_i
    if Person.where(ssn: ssn).count < 1
      count = count+1
    end
  end
  ssn
end

def generate_dob(age)
  current_date = TimeKeeper.date_of_record
  dob = Date.new(current_date.year-age, current_date.month, current_date.day)
end


def generate_relation(person_id, dependent_id, kind, family_id)
  predecessor = Person.where(id: person_id).first
  successor = Person.where(id: dependent_id).first
  predecessor.add_relationship(successor, kind, family_id, true)
  successor.add_relationship(predecessor, PersonRelationship::InverseMap[kind], family_id)
end

def destroy_core_family(existing_user)
  relationships = existing_user.person.person_relationships if existing_user.person.person_relationships.present?
  if relationships.present? && relationships.count >0
    relationships.each do |person_relationship|
      if person_relationship.relative_id.present?
        Person.where(id: person_relationship.relative_id).first.destroy
      end
    end
  end
  existing_user.person.primary_family.destroy if existing_user.person.primary_family.present?
  existing_user.person.destroy if existing_user.person.present?
  existing_user.destroy
end

def create_vlp_for_consumer_role(vlp_documents, person)
  vlp_documents.each do |k, v|
    if v!= 1
      person.consumer_role.vlp_documents.create!(v)
    end
  end
end