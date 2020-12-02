class HistoryTracker
  include Mongoid::History::Tracker

  after_create :check_history_trackers

  TRACK_HISTORY_ON = %w- consumer_role -

  index({"association_chain.0.id" => 1, "association_chain.0.name" => 1, "scope" => 1})

  def check_history_trackers
    TRACK_HISTORY_ON.each do |collection|
      add_tracking_record(collection) if checking_object(collection)::COLLECTIONS_TO_TRACK.include?(find_collection)
    end
  end

  def checking_object(collection)
    Object.const_get(collection.camelize)
  end

  def create_history_element
    HistoryActionTracker.new({ :actor => actor,
                               :action => self[:action],
                               :history_tracker_id => id,
                               :tracked_collection => find_collection,
                               :details => check_details_to_store })
  end

  def actor
    existing_user = User.where(_id: SAVEUSER[:current_user_id]).first
    if existing_user
      existing_user.email || existing_user.hbx_id || existing_user.id
    else
      "external source"
    end
  end

  def check_details_to_store
    #this is just an example how we can use this attribute
    if find_collection == "ssa_request"
      "expand ssa request"
    else
      self[:action] + ": " + actor
    end
  end

  def find_collection
    association_chain.last["name"]
  end

  def tracking_node(model)
    case model
      when "Person"
        Person.all_consumer_roles.where(id: association_chain.first["id"])
      when "Family"
        # takes only families from IVL market
        Family.by_enrollment_individual_market.where(id: association_chain.first["id"])
    end
  end

  def record_consumer_element
    if self[:action] == "create" && last_chain_element == "Person"
      #do nothing now
    else
      if tracking_node("Person").exists?
        person = tracking_node("Person").first
        person.consumer_role.history_action_trackers << create_history_element
      end
    end
  end

  def record_enrollment_element
    if tracking_node("Family").exists?
      if last_chain_element == "hbx_enrollments"
        family = Family.where("households.hbx_enrollments._id" => association_chain.last["id"]).first
        if family && family.active_household.hbx_enrollments.any?
          enrollment = family.active_household.hbx_enrollments.find_by(id:association_chain.last["id"])
          enrollment.hbx_enrollment_members.each do |enrollment_member|
            person = enrollment_member.family_member.person
            person.consumer_role.history_action_trackers << create_history_element if person.consumer_role
          end
        end
      end
    end

  end

  def first_chain_element
    association_chain.first["name"]
  end

  def last_chain_element
    association_chain.last["name"]
  end

  def add_tracking_record(collection)
    if collection == "consumer_role"
      case first_chain_element
        when "Person"
          record_consumer_element
        when "Family"
          record_enrollment_element
      end
    end
  end
end
