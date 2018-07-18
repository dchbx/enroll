module SponsoredBenefits
  class Site
    include Mongoid::Document
    include Mongoid::Timestamps

    SITE_KEY_MAX_LENGTH = 6

    # attr_reader :subdomain, :site_key

    ## General settings for site

    # Unique, short identifier for this site
    field :site_key,    type: Symbol  # For example, :dc, :cca

    # Web site owner's formal agency or business name. Appear in formal locations, such as copyright attribution
    field :long_name,   type: String

    # Name for this Web site.  Used as title in web site header, system messages, notices, etc.
    field :short_name,  type: String

    # Site description or slogan that will appear on portal header
    field :byline,      type: String

    # The site's Worldwide Web base address (e.g. hbxshop.org)
    field :domain_name, type: String

    # The fully qualified domain name for the web site (e.g. https://enroll.mhc.hbxshop.org)
    field :home_url,    type: String

    # The fully qualified domain name for the web site's help index page (e.g. https://mhc.hbxshop.org/help)
    field :help_url,    type: String

    # The fully qualified domain name for the web site's Frequently Asked Questions index page (e.g. https://mhc.hbxshop.org/help)
    field :faqs_url,    type: String

    # The starting calendar year for reserving web site content copyright (year site became active)
    field :copyright_period_start,  type: String, default: ->{ ::TimeKeeper.date_of_record.year }

    # File name for the site's logo
    field :logo_file_name,  type: String # convention: site_key + "_logo.png"

    # TODO Deprecate logo file name and store as binary in database to support multitenancy
    field :logo,        type: BSON::Binary


    # TODO -- come up with scheme to manage/store these attributes and provide defaults
    field :colors,  type: Array


    # Organization responsible for administering this site
    has_one   :owner_organization, inverse_of: :site_owner,
              class_name: "SponsoredBenefits::Organizations::ExemptOrganization"

    # Set of organizations who offer, broker and sponsor benefits on this site
    has_many  :site_organizations, inverse_of: :site,
              class_name: "SponsoredBenefits::Organizations::Organization"

    # Curated collections of benefits intended for specific sponsor and member groups
    has_many :benefit_markets,
             class_name: "BenefitMarkets::BenefitMarket"


    accepts_nested_attributes_for :owner_organization

    # has_many :families,         class_name: "::Family"

    validates_presence_of :site_key, :owner_organization
    validate :association_limits


    scope :by_site_key,   ->(site_key) { where(site_key: site_key) }

    index({ site_key:  1 }, { unique: true })

    def subdomain
      site_key.to_s unless site_key.blank?
    end

    # Using a passed string, prepare and set a site identifier that meets validation requirements
    def site_key=(new_site_key)
      valid_id = scrub_site_key(new_site_key)
      write_attribute(:site_key, valid_id.to_sym) if valid_id.present?
      site_key
    end

    def benefit_market_for(kind)
      benefit_markets.detect { |market| market.kind == kind }
    end

    private

    # Valid IDs are less than or equal to SITE_KEY_MAX_LENGTH characters, composed of letters and numbers only
    # (no special characters), all lower case, and may not begin with a number
    def scrub_site_key(site_key)
      raise InvalidArgumentError, "numeric site_key not allowed" if site_key.numeric? || site_key.blank?
      strip_leading_numbers(site_key.to_s).parameterize.gsub(/[-_]/,'').slice(0, SITE_KEY_MAX_LENGTH).to_sym
    end

    def strip_leading_numbers(input_string)
      while input_string.chr.numeric? do
        input_string = input_string.slice!(1, input_string.length - 1)
      end
      input_string
    end

    def association_limits
      SponsoredBenefits::BENEFIT_MARKET_KINDS.each do |market_kind|
        market_count = benefit_markets.select { |market| market.kind == market_kind }
        if market_count.size > 1
          errors.add(:benefit_markets, "cannot be more than one #{market_kind}")
        end
      end
    end


  end
end
