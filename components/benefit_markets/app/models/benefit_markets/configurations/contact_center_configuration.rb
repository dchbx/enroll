module BenefitMarkets
  class ContactCenterConfiguration
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :benefit_market

    field :name,      type: String
    field :alt_name,  type: String
    field :fax,       type: String
    field :alt_fax,   type: String
    field :non_discrimination_email,   type: String
    field :non_discrimination_phone_1, type: String
    field :non_discrimination_phone_2, type: String
    field :non_discrimination_phone_3, type: String
    field :non_discrimination_complaint_url, type: String

    embeds_many :emails,    class_name: "::Email"
    embeds_many :phones,    class_name: "::Phone"
    embeds_many :addresses, class_name: "::Address"


    # contact_center.phone_number:
    # contact_center.tty_number:
    # contact_center.alt_phone_number:
    # contact_center.payment_phone_number:
    # contact_center.ivl_number:
    # contact_center.ivl_phone_number:

    # contact_center.email_address:
    # contact_center.small_business_email:
    # contact_center.non_discrimination_email:
    # contact_center.appeals_email:

    # contact_center.mailing_address.name:
    # contact_center.mailing_address.address_1:
    # contact_center.mailing_address.address_2:
    # contact_center.mailing_address.city:
    # contact_center.mailing_address.state:
    # contact_center.mailing_address.zip_code:

    # contact_center.appeal_center.name:
    # contact_center.appeal_center.address_1:
    # contact_center.appeal_center.address_2:
    # contact_center.appeal_center.city:
    # contact_center.appeal_center.state:
    # contact_center.appeal_center.zip_code:

  end
end
