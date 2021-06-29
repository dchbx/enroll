# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# rubocop:disable Metrics/BlockNesting
class MigrateVerificationTypes < MongoidMigrationTask
  def get_people(offset, limit)
    Person.where(:consumer_role => {"$exists" => true}).offset(offset).limit(limit)
  end

  def local_residency
    EnrollRegistry[:enroll_app].setting(:state_residency).item
  end

  def migrate
    run_size = 500
    offset = 0
    while offset < Person.count
      people = get_people(offset, run_size)
      people.each do |person|

        ensure_verification_types(person)
        puts "Person HBX_ID: #{person.hbx_id} verification_types where moved" unless Rails.env.test?
      rescue StandardError
        warn "Issue :ensure_verification_types: person #{person.id}, HBX id  #{person.hbx_id}"

      end
      offset += run_size
    end
  end

  def ensure_verification_types(person)
    live_types = []
    live_types << local_residency
    live_types << 'Social Security Number' if person.ssn
    live_types << 'American Indian Status' unless person.tribal_id.nil? || person.tribal_id.empty?
    live_types << if person.us_citizen
                    'Citizenship'
                  else
                    'Immigration status'
                  end
    person.verification_types.delete_all
    live_types.each do |type|
      add_new_verification_type(person, type)
    end
  end

  def add_new_verification_type(person, type)
    person.verification_types << VerificationType.new(
      :type_name => type,
      :validation_status => assign_verification_type_status(type, person),
      :update_reason => type_update_reason(person, type),
      :rejected => type_rejected(person, type),
      :due_date => due_date(person, type),
      :due_date_type => due_date_type(person, type),
      :type_history_elements => create_type_history_elements(person, type),
      :vlp_documents => create_vlp_documents(person, type)
    )
  end

  def create_vlp_documents(person, type)
    documents = []
    person.consumer_role.vlp_documents.where(verification_type: type).each do |elem|
      documents << Document.new(:title => elem.title,
                                :creator => elem.creator,
                                :identifier => elem.identifier,
                                :created_at => elem.created_at,
                                :updated_at => elem.updated_at)
    end
    documents
  end

  def create_type_history_elements(person, type)
    history_element = []
    person.consumer_role.verification_type_history_elements.where(verification_type: type).each do |elem|
      history_element << TypeHistoryElement.new(:action => elem.action,
                                                :created_at => elem.created_at,
                                                :updated_at => elem.updated_at,
                                                :modifier => elem.modifier,
                                                :update_reason => elem.update_reason,
                                                :event_response_record_id => elem.event_response_record_id,
                                                :event_request_record_id => elem.event_request_record_id)
    end
    history_element
  end

  def due_date(person, type)
    sv = person.consumer_role.special_verifications.where(verification_type: type).order_by(:created_at.desc).first
    sv.due_date if sv.present?
  end

  def due_date_type(person, type)
    sv = person.consumer_role.special_verifications.where(verification_type: type).order_by(:created_at.desc).first
    sv.type if sv.present?
  end

  def type_rejected(person, type)
    case type
    when local_residency
      person.consumer_role.residency_rejected
    when 'Social Security Number'
      person.consumer_role.ssn_rejected
    when 'American Indian Status'
      person.consumer_role.native_rejected
    when 'Citizenship' || 'Immigration status'
      person.consumer_role.lawful_presence_rejected
    end
  end

  def type_update_reason(person, type)
    case type
    when local_residency
      person.consumer_role.residency_update_reason
    when 'Social Security Number'
      person.consumer_role.ssn_update_reason
    when 'American Indian Status'
      person.consumer_role.native_update_reason
    when 'Citizenship'
      reason = person.consumer_role.lawful_presence_update_reason
      person.consumer_role.lawful_presence_update_reason[:update_reason] if reason && reason[:v_type] == 'Citizenship'
    when 'Immigration status'
      reason = person.consumer_role.lawful_presence_update_reason
      person.consumer_role.lawful_presence_update_reason[:update_reason] if reason && reason[:v_type] == 'Immigration status'
    end
  end

  def assign_verification_type_status(type, person)
    consumer = person.consumer_role
    if consumer.vlp_authority == "curam" && consumer.fully_verified?
      "curam"
    else
      case type
      when 'Social Security Number'
        if consumer.ssn_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.ssn_rejected
          "review"
        elsif consumer.ssa_pending?
          "pending"
        else
          "outstanding"
        end
      when 'American Indian Status'
        if consumer.native_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.native_rejected
          "review"
        else
          "outstanding"
        end
      when local_residency
        if consumer.residency_verified?
          consumer.residency_attested? ? "attested" : "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.residency_rejected
          "review"
        elsif consumer.residency_pending?
          "pending"
        else
          "outstanding"
        end
      else
        if consumer.lawful_presence_verified?
          "verified"
        elsif consumer.has_docs_for_type?(type) && !consumer.lawful_presence_rejected
          "review"
        elsif consumer.citizenship_immigration_processing?
          "pending"
        else
          "outstanding"
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockNesting
