## Product premium costs for a specified time period
# Effective periods:
#   DC & MA SHOP Health: Q1, Q2, Q3, Q4
#   DC Dental: annual
#   GIC Medicare: Jan-June, July-Dec
#   DC & MA IVL: annual

module BenefitMarkets
  class Products::PremiumTable
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :product, class_name: "BenefitMarkets::Products::Product"

    field       :effective_period,  type: Range


    belongs_to  :rating_area,
                class_name: "BenefitMarkets::Locations::RatingArea"

    embeds_many :premium_tuples,
                class_name: "BenefitMarkets::Products::PremiumTuple"

    validates_presence_of :effective_period, :rating_area
    # validates_presence_of :premium_tuples, :allow_blank => false


    scope :effective_period_cover,    ->(compare_date = TimeKeeper.date_of_record) { where(
                                                                           :"effective_period.min".lte => compare_date,
                                                                           :"effective_period.max".gte => compare_date)
                                                                        }
    def comparable_attrs
      [:effective_period, :rating_area]
    end

    # Define Comparable operator
    # If instance attributes are the same, compare PremiumTuples
    def <=>(other)
      if comparable_attrs.all? { |attr| send(attr) == other.send(attr) }
        if premium_tuples.to_a == other.premium_tuples.to_a
          0
        else
          premium_tuples.to_a <=> other.premium_tuples.to_a
        end
      else
        other.updated_at.blank? || (updated_at < other.updated_at) ? -1 : 1
      end
    end

    def create_copy_for_embedding
      self.class.new(self.attributes.except(:premium_tuples))
    end
  end
end
