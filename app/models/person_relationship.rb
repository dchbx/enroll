class PersonRelationship
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  MaleRelationships   = %W(father grandfather grandson uncle nephew adopted\ child stepparent
                              foster\ child son-in-law brother-in-law father-in-law brother ward
                              stepson child sponsored\ dependent dependent\ of\ a\ minor\ dependent
                              guardian court\ appointed\ guardian collateral\ dependent life\ partner)

  FemaleRelationships = %W(mother grandmother granddaughter aunt niece adopted\ child stepparent
                              foster\ child daughter-in-law sister-in-law mother-in-law sister ward
                              stepdaughter child sponsored\ dependent dependent\ of\ a\ minor\ dependent
                              guardian court\ appointed\ guardian collateral\ dependent life\ partner)

  Relationships = [
    "spouse",
    "life_partner",
    "child",
    "adopted_child",
    "annuitant", # no inverse
    "aunt_or_uncle",
    "brother_or_sister_in_law",
    "collateral_dependent",
    "court_appointed_guardian",
    "daughter_or_son_in_law",
    "dependent_of_a_minor_dependent",
    "father_or_mother_in_law",
    "foster_child",
    "grandchild",
    "grandparent",
    "great_grandchild",
    "great_grandparent",
    "guardian",
    "nephew_or_niece",
    "other_relationship",
    "parent",
    "sibling",
    "sponsored_dependent",
    "stepchild",
    "stepparent",
    "trustee", # no inverse
    "unrelated",
    "ward"
  ]

  Relationships_UI = [
    "spouse",
    "domestic_partner",
    "child",
    "parent",
    "sibling",
    "unrelated",
    "aunt_or_uncle",
    "nephew_or_niece",
    "grandchild",
    "grandparent"
  ]

  InverseMap = {
    "child" => "parent",
    "parent" => "child",
    "grandparent" => "grandchild",
    "grandchild" => "grandparent",
    "great_grandparent" => "great_grandchild",
    "great_grandchild" => "great_grandparent",
    "stepparent" => "stepchild",
    "stepchild" => "stepparent",
    "aunt_or_uncle" => "nephew_or_niece",
    "nephew_or_niece" => "aunt_or_uncle",
    "father_or_mother_in_law" => "daughter_or_son_in_law",
    "daughter_or_son_in_law" => "father_or_mother_in_law",
    "guardian" => "ward",
    "ward" => "guardian",

    # bi directional
    "self" => "self",
    "brother_or_sister_in_law" => "brother_or_sister_in_law",
    "sibling" => "sibling",
    "life_partner" => "life_partner",
    "spouse" => "spouse",
    "other_relationship" => "other_relationship",
    "cousin" => "cousin",
    "unrelated" => "unrelated",

    #one directional
    "foster_child" => "guardian",
    "court_appointed_guardian" => "ward",
    "adopted_child" => "parent"
  }

  SymmetricalRelationships = %W[head\ of\ household spouse ex-spouse cousin ward trustee annuitant other\ relationship other\ relative self]

  Kinds = SymmetricalRelationships | Relationships | BenefitEligibilityElementGroup::INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS

  field :relative_id, type: BSON::ObjectId
  field :kind, type: String

	validates_presence_of :relative_id, message: "Choose a relative"
  validates :kind,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: Kinds, message: "%{value} is not a valid person relationship"}

  after_save :notify_updated

  def notify_updated
    person.notify_updated
  end

  def parent
    raise "undefined parent class: Person" unless person?
    self.person
  end

  def relative=(new_person)
    raise ArgumentError.new("expected Person") unless new_person.is_a? Person
    self.relative_id = new_person._id
    @relative = new_person
  end

  def relative
    return @relative if defined? @relative
    @relative = Person.find(self.relative_id) unless self.relative_id.blank?
  end

  def invert_relationship
    self.kind = InverseMap[self.kind]
    self
  end
end
