module BenefitSponsors
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
    #    has_one   :owner_organization, inverse_of: :site_owner,
    #              class_name: "BenefitSponsors::Organizations::ExemptOrganization"

    # Set of organizations who offer, broker and sponsor benefits on this site
    #    has_many  :site_organizations, inverse_of: :site,
    #              class_name: "BenefitSponsors::Organizations::Organization"

    # Curated collections of benefits intended for specific sponsor and member groups
    has_and_belongs_to_many :benefit_markets,
      class_name: "::BenefitMarkets::BenefitMarket", :inverse_of => nil
  end
end
