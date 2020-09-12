# frozen_string_literal: true

module FinancialAssistance
  class Relationship

    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :application, class_name: "::FinancialAssistance::Application", inverse_of: :relationships

    RELATIONSHIPS = [
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
      "ward",
      "stepson_or_stepdaughter"
    ].freeze

    RELATIONSHIPS_UI = [
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
    ].freeze

    INVERSE_MAP = {
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
      "domestic_partner" => "domestic_partner",

      #one directional
      "foster_child" => "guardian",
      "court_appointed_guardian" => "ward",
      "adopted_child" => "parent",
      "stepson_or_stepdaughter" => "stepparent"
    }.freeze

    Kinds = RELATIONSHIPS

    field :kind, type: String
    field :applicant_id, type: BSON::ObjectId # predecessor or from
    field :relative_id, type: BSON::ObjectId # successor or to

    def applicant
      return @applicant if defined? @applicant
      @applicant = FinancialAssistance::Applicant.find(applicant_id)
    end

    def relative
      return @relative if defined? @relative
      @relative = FinancialAssistance::Applicant.find(relative_id)
    end
  end
end
