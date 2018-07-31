class FamilySearch
  class FamilySearchMember < ::FamilyMember
    include Mongoid::Document
    embeds_one :person
  end

  class FamilySearchFamily < ::Family
    include Mongoid::Document
    embeds_many :family_members, class_name: "::FamilySearch::FamilySearchMember"
  end

  include Mongoid::Document

  store_in collection: :families_search

  embeds_one :value, class_name: "::FamilySearch::FamilySearchFamily"

  def family
    value
  end
end
