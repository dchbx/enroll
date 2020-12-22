# Support product import from SERFF, CSV templates, etc

# Effective dates during which sponsor may purchase this product at this price
## DC SHOP Health   - annual product changes & quarterly rate changes
## CCA SHOP Health  - annual product changes & quarterly rate changes
## DC IVL Health    - annual product & rate changes
## Medicare         - annual product & semiannual rate changes

module BenefitMarkets
  class Products::Product
    include Mongoid::Document
    include Mongoid::Timestamps

    CSR_KIND_TO_PRODUCT_VARIANT_MAP = ::EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP
    MARKET_KINDS = %w[shop individual].freeze
    INDIVIDUAL_MARKET_KINDS = %w[individual coverall].freeze

    field :benefit_market_kind,   type: Symbol

    # Time period during which Sponsor may include this product in benefit application
    field :application_period,    type: Range   # => Mon, 01 Jan 2018..Mon, 31 Dec 2018

    field :hbx_id,                type: String
    field :title,                 type: String
    field :description,           type: String,         default: ""
    field :issuer_profile_id,     type: BSON::ObjectId
    field :product_package_kinds, type: Array,          default: []
    field :kind,                  type: Symbol,         default: ->{ product_kind }
    field :premium_ages,          type: Range,          default: 0..65
    field :provider_directory_url,      type: String
    field :is_reference_plan_eligible,  type: Boolean,  default: false

    field :deductible, type: String
    field :family_deductible, type: String
    field :issuer_assigned_id, type: String
    field :service_area_id, type: BSON::ObjectId
    field :network_information, type: String
    field :nationwide, type: Boolean # Nationwide
    field :dc_in_network, type: Boolean # DC In-Network or not
    embeds_one  :sbc_document, as: :documentable,
                :class_name => "::Document"

    embeds_many :premium_tables,
                class_name: "BenefitMarkets::Products::PremiumTable"

    # validates_presence_of :hbx_id
    validates_presence_of :application_period, :benefit_market_kind, :title, :service_area

    validates :benefit_market_kind,
              presence: true,
              inclusion: {in: BENEFIT_MARKET_KINDS, message: "%{value} is not a valid benefit market kind"}

    index({ hbx_id: 1 }, {name: "products_hbx_id_index"})
    index({ service_area_id: 1}, {name: "products_service_area_index"})

    index({ "application_period.min" => 1,
            "application_period.max" => 1,
            },
            {name: "products_application_period_index"}
          )

    index({ "benefit_market_kind" => 1,
            "kind" => 1,
            "product_package_kinds" => 1
            },
            {name: "product_market_kind_product_package_kind_index"}
          )

    index({ "premium_tables.effective_period.min" => 1,
            "premium_tables.effective_period.max" => 1 },
            {name: "products_premium_tables_effective_period_index"}
          )

    index({ "benefit_market_kind" => 1,
            "kind" => 1,
            "product_package_kinds" => 1,
            "application_period.min" => 1,
            "application_period.max" => 1,
            },
            {name: "products_product_package_date_search_index"}
          )

    index({ "premium_tables.rating_area" => 1,
            "premium_tables.effective_period.min" => 1,
            "premium_tables.effective_period.max" => 1 },
            {name: "products_premium_tables_search_index"}
          )

    scope :by_product_package,    ->(product_package) { 
              where(
                :"benefit_market_kind"          => product_package.benefit_kind,
                :"kind"                         => product_package.product_kind,
                :"product_package_kinds".in     => [product_package.package_kind]
              ).by_application_period(product_package.application_period)
            }

    scope :aca_shop_market,             ->{where(benefit_market_kind: :aca_shop) }
    scope :aca_individual_market,       ->{ where(benefit_market_kind: :aca_individual) }
    scope :congressional_market,        ->{ where(benefit_market_kind: :fehb) }
    scope :by_benefit_market_kind,      ->(benefit_market_kind) { where(benefit_market_kind: benefit_market_kind) }
    scope :by_issuer_profile,           ->(issuer_profile){ where(issuer_profile_id: issuer_profile.id) }
    scope :by_issuer_profile_id,        ->(issuer_profile_id){ where(issuer_profile_id: issuer_profile_id) }
    scope :by_kind,                     ->(kind){ where(kind: kind) }
    scope :by_service_area,             ->(service_area){ where(service_area: service_area) }
    scope :by_service_areas,            ->(service_area_ids) { where("service_area_id" => {"$in" => service_area_ids }) }

=begin
    scope :by_coverage_date, ->(coverage_date) {
      where(
        "premium_tables.effective_period" => {
          "$elemMatch" => {
              "min" => { "$lte" => coverage_date },
              "max" => { "$gte" => coverage_date }
          }
        }
      )
    }
=end
    scope :by_metal_level_kind,         ->(metal_level){ where(metal_level_kind: /#{metal_level}/i) }
    scope :by_state,                    ->(state) {where(
      :"issuer_profile_id".in => BenefitSponsors::Organizations::Organization.issuer_profiles.where(:"profiles.issuer_state" => state).map(&:issuer_profile).map(&:id)
    )}

    scope :effective_with_premiums_on,  ->(effective_date){ where(:"premium_tables.effective_period.min".lte => effective_date,
                                                                  :"premium_tables.effective_period.max".gte => effective_date) }

    # input: application_period type: :Date
    # ex: application_period --> [2018-02-01 00:00:00 UTC..2019-01-31 00:00:00 UTC]
    #     BenefitProduct avilable for both 2018 and 2019
    # output: might pull multiple records
    scope :by_application_period,       ->(application_period){ 
      where(
        "$or" => [
          {"application_period.min" => {"$lte" => application_period.max, "$gte" => application_period.min}},
          {"application_period.max" => {"$lte" => application_period.max, "$gte" => application_period.min}},
          {"application_period.min" => {"$lte" => application_period.min}, "application_period.max" => {"$gte" => application_period.max}}
        ])
    }

    scope :by_year, lambda {|year|
      where('$and' => [{'application_period.min' => {'$lte' => Date.new(year.to_i)}},
                       {'application_period.max' => {'$gte' => Date.new(year.to_i).end_of_year}}
      ])
    }

    scope :with_premium_tables, ->{ where(:premium_tables.exists => true) }

    scope :by_product_ids, ->(product_ids) { where(:id => {'$in' => product_ids}) }

    scope :by_csr_kind_with_catastrophic, lambda {|csr_kind = 'csr_0'|
      where('$or' => [{:metal_level_kind.in => [:platinum, :gold, :bronze, :catastrophic], :csr_variant_id => '01'},
                      {:metal_level_kind => :silver, :csr_variant_id => CSR_KIND_TO_PRODUCT_VARIANT_MAP[csr_kind]}])
    }

    #Products retrieval by type
    scope :health_products,            ->{ where(:"_type" => /.*HealthProduct$/) }
    scope :dental_products,            ->{ where(:"_type" => /.*DentalProduct$/)}

    # Highly nested scopes don't behave in a way I entirely understand with
    # respect to the $elemMatch operator.  Since we are only invoking this
    # method when we already have the document, I'm going to abuse lazy
    # enumeration to create something that behaves like a scope but will
    # only be evaluated once.
    def self.by_coverage_date(collection, coverage_date)
      collection.select do |product|
        product.premium_tables.any? do |pt| 
          (pt.effective_period.min <= coverage_date) && (pt.effective_period.max >= coverage_date)
        end
      end
    end

    def service_area_id=(val)
      write_attribute(:service_area_id, val)
      if val.nil?
        @service_area = nil
      else
        @service_area = ::BenefitMarkets::Locations::ServiceArea.find(service_area_id)
      end
    end

    def service_area=(val)
      @service_area = val
      if val.nil?
        write_attribute(:service_area_id, nil)
      else
        write_attribute(:service_area_id, val.id)
      end
    end

    def network
      return 'Nationwide' if nationwide
      return 'DC-Metro' if dc_in_network
    end

    def can_use_aptc?
      health? && metal_level != 'catastrophic'
    end

    def is_csr?
      csr_kinds_mapping = CSR_KIND_TO_PRODUCT_VARIANT_MAP
      (csr_kinds_mapping.values - [csr_kinds_mapping.default]).include? csr_variant_id
    end

    def ehb
      percent = read_attribute(:ehb)
      (percent && percent > 0) ? percent : 1
    end

    def service_area
      return nil if service_area_id.blank?
      @service_area ||= ::BenefitMarkets::Locations::ServiceArea.find(service_area_id)
    end

    def name
      title
    end

    def carrier_profile
      issuer_profile
    end

    def min_cost_for_application_period(effective_date)
      p_tables = premium_tables.effective_period_cover(effective_date)
      if premium_tables.any?
        p_tables.flat_map(&:premium_tuples).select do |pt|
          pt.age == premium_ages.min
        end.min_by { |pt| pt.cost }.cost
      end
    end

    def max_cost_for_application_period(effective_date)
      p_tables = premium_tables.effective_period_cover(effective_date)
      if premium_tables.any?
        p_tables.flat_map(&:premium_tuples).select do |pt|
          pt.age == premium_ages.min
        end.max_by { |pt| pt.cost }.cost
      end
    end

    def cost_for_application_period(application_period)
      p_tables = premium_tables.effective_period_cover(application_period.min)
      if premium_tables.any?
        p_tables.flat_map(&:premium_tuples).select do |pt|
          pt.age == premium_ages.min
        end.min_by { |pt| pt.cost }.cost
      end
    end

    def deductible_value
      return nil if deductible.blank?
      deductible.split(".").first.gsub(/[^0-9]/, "").to_i
    end

    def family_deductible_value
      return nil if family_deductible.blank?
      deductible.split("|").last.split(".").first.gsub(/[^0-9]/, "").to_i
    end

    def product_kind
      kind_string = (self.class.to_s.demodulize.sub!('Product','').downcase)
      kind_string.present? ? kind_string.to_sym : :product_base_class
    end

    def comparable_attrs
      [
        :hbx_id, :benefit_market_kind, :application_period, :title, :description,
        :issuer_profile_id, :service_area
      ]
    end

    # Define Comparable operator
    # If instance attributes are the same, compare PremiumTables
    def <=>(other)
      if comparable_attrs.all? { |attr| send(attr) == other.send(attr) }
        if premium_tables.count != other.premium_tables.count
          premium_tables.count <=> other.premium_tables.count
        else
          premium_tables.to_a <=> other.premium_tables.to_a
        end
      else
        other.updated_at.blank? || (updated_at < other.updated_at) ? -1 : 1
      end
    end

    def issuer_profile
      return @issuer_profile if defined?(@issuer_profile)
      @issuer_profile = ::BenefitSponsors::Organizations::IssuerProfile.find(self.issuer_profile_id)
    end

    def issuer_profile=(new_issuer_profile)
      write_attribute(:issuer_profile_id, new_issuer_profile.id)
      @issuer_profile = new_issuer_profile
    end

    def active_year
      application_period.min.year
    end

    def find_carrier_info
      return '' if issuer_profile.legal_name.nil?

      issuer_profile.legal_name
    end

    def display_carrier_logo(options = {:width => 50})
      carrier_name = find_carrier_info
      "<img src=\"\/assets\/logo\/carrier\/#{carrier_name.parameterize.underscore}.jpg\" width=\"#{options[:width]}\"/>"
    end

    def premium_table_effective_on(effective_date)
      premium_tables.detect { |premium_table| premium_table.effective_period.cover?(effective_date) }
    end

    # Add premium table, covering extended time period, to existing product.  Used for products that
    # have periodic rate changes, such as ACA SHOP products that are updated quarterly.
    def add_premium_table(new_premium_table)
      raise InvalidEffectivePeriodError unless is_valid_premium_table_effective_period?(new_premium_table)

      if premium_table_effective_on(new_premium_table.effective_period.min).present? ||
          premium_table_effective_on(new_premium_table.effective_period.max).present?
        raise DuplicatePremiumTableError, "effective_period may not overlap existing premium_table"
      else
        premium_tables << new_premium_table
      end
      self
    end

    def update_premium_table(updated_premium_table)
      raise InvalidEffectivePeriodError unless is_valid_premium_table_effective_period?(updated_premium_table)

      drop_premium_table(premium_table_effective_on(updated_premium_table.effective_period.min))
      add_premium_table(updated_premium_table)
    end

    def drop_premium_table(premium_table)
      premium_tables.delete(premium_table) unless premium_table.blank?
    end

    def is_valid_premium_table_effective_period?(compare_premium_table)
      return false unless application_period.present? && compare_premium_table.effective_period.present?

      if application_period.cover?(compare_premium_table.effective_period.min) &&
          application_period.cover?(compare_premium_table.effective_period.max)
        true
      else
        false
      end
    end

    def add_product_package(new_product_package)
      product_packages.push(new_product_package).uniq!
      product_packages
    end

    def drop_product_package(product_package)
      product_packages.delete(product_package) { "not found" }
    end

    def create_copy_for_embedding
      self.class.new(self.attributes.except(:premium_tables)).tap do |new_product|
        new_product.premium_tables = self.premium_tables.map { |pt| pt.create_copy_for_embedding }
      end
    end

    def health?
      kind == :health
    end

    def dental?
      kind == :dental
    end

    def is_same_plan_by_hios_id_and_active_year?(product)
      #a combination of hios_id and active_year has to be considered as a Primary Key as hios_id alone cannot be considered as primary
      ((self.hios_id.split("-")[0] == product.hios_id.split("-")[0]) && self.active_year == product.active_year )
    end

    # private
    # self.class.new(attrs_without_tuples)
    # def attrs_without_tuples
    #   attributes.inject({}) do |attrs, (key, val)|
    #     if key == "premium_tables"
    #       attrs[key] = val.map do |pt| 
    #         pt.tap {|t| t.delete("premium_tuples") }
    #       end
    #     elsif key == "sbc_document"
    #       attrs
    #     else
    #       attrs[key] = val
    #     end
    #     attrs
    #   end
    # end
  end
end
