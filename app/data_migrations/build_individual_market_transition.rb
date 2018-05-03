require File.join(Rails.root, "lib/mongoid_migration_task")

class BuildIndividualMarketTransition < MongoidMigrationTask


  def migrate
    action = ENV['action'].to_s
    case action
      when 'consumer_role_people'
        build_individual_market_transition_for_consumer_role_people
      when 'resident_role_people'
        build_individual_market_transition_for_resident_role_people
    end
  end

  def build_individual_market_transition_for_consumer_role_people
    batch_size = 500
    offset = 0
    people = get_consumer_role_people
    while (offset < people.count)
      people.offset(offset).limit(batch_size).each do |person|
        begin
          person.individual_market_transitions.build(role_type: 'consumer',
                                                     reason_code: 'initial_individual_market_transition_created_using_data_migration',
                                                     effective_starting_on:  person.consumer_role.created_at.to_date,
                                                     submitted_at: ::TimeKeeper.datetime_of_record)
          person.save!
          puts "Individual market transitions with role type as consumer added for person with HBX_ID: #{person.hbx_id}" unless Rails.env.test?
        rescue => e
          puts "unable to add individual market transition for person with hbx_id #{person.hbx_id}" + e.message unless Rails.env.test?
        end
      end
      offset = offset + batch_size
    end
  end


  def build_individual_market_transition_for_resident_role_people
    people = get_resident_role_people
    people.each do |person|
      begin
        person.individual_market_transitions.build(role_type: 'resident',
                                                   reason_code: 'initial_individual_market_transition_created_using_data_migration',
                                                   effective_starting_on: person.resident_role.created_at.to_date,
                                                   submitted_at: ::TimeKeeper.datetime_of_record)
        person.save!
        puts "Individual market transitions with role type as resident added for person with HBX_ID: #{person.hbx_id}" unless Rails.env.test?
      rescue => e
        puts "unable to add individual market transition for person with hbx_id #{person.hbx_id}" + e.message unless Rails.env.test?
      end
    end
  end

  def get_consumer_role_people
    Person.where(:"consumer_role" => {:"$exists" => true}, :"resident_role" => {:"$exists" => false})
  end

  def get_resident_role_people
    Person.where(:"resident_role" => {:"$exists" => true}, :"consumer_role" => {:"$exists" => false})
  end

end
