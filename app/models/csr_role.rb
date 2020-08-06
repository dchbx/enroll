# frozen_string_literal: true

class CsrRole
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include Mongoid::History::Trackable

  embedded_in :person

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person
  field :organization, type: String
  field :shift, type: String
  field :cac, type: Boolean, default: false

  track_history :on => [:fields],
                :scope => :person,
                :modifier_field => :modifier,
                :modifier_field_optional => true,
                :version_field => :tracking_version,
                :track_create => true,    # track document creation, default is false
                :track_update => true,    # track document updates, default is true
                :track_destroy => true

  def parent
    person
  end

  class << self

    def find_by_name(first_name, last_name, cac_flag)
      staff = Person.where(:'csr_role.cac' => cac_flag)
      staff.where(:$and => [{first_name: /^#{first_name}$/i},{last_name: /^#{last_name}$/i}])
    end

    def find(id)
      return nil if id.blank?
      people = Person.where("csr_role._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].csr_role : nil
    end

    def list_csrs(person_list)
      person_list.reduce([]) { |csrs, person| csrs << person.csr_role }
    end

    # TODO; return as chainable Mongoid::Criteria
    def all
      # criteria = Mongoid::Criteria.new(Person)
      list_csrs(Person.where(csr_role: {:$exists => true}))
    end

    def first
      all.first
    end

    def last
      all.last
    end
  end
end
