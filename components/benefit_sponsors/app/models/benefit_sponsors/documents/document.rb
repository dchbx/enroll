module BenefitSponsors
  module Documents
    class Document
      include Mongoid::Document
      include Mongoid::Timestamps
      include ::BenefitSponsors::ModelEvents::Document
      include BenefitSponsors::Concerns::Observable
      include Config::AcaModelConcern

      SUBJECT_KINDS = %w(
                          urn:openhbx:documents:v1::employer#invoice
                          urn:openhbx:documents:v1::employer#eligibility_attestation
                          urn:openhbx:documents:v1::broker#commission_statement
                      )
                      
      ACCESS_RIGHTS = %w(public pii_restricted)

      after_save :notify_on_save

      add_observer ::BenefitSponsors::Observers::DocumentObserver.new, [:notifications_send]

      belongs_to :documentable, polymorphic: true

      # Dublin Core metadata elements
      field :title, type: String, default: "untitled"

      # Entity responsible for making the resource - person, organization or service
      field :creator, type: String, default: "dchl"

      # Controlled vocabulary w/classification codes. Mapped to ConsumerRole::VLP_DOCUMENT_KINDS
      field :subject, type: String

      # May include but is not limited to: an abstract, a table of contents, a graphical representation, or a free-text account of the resource
      field :description, type: String

      # Entity responsible for making the resource available - person, organization or service
      field :publisher, type: String, default: "dchl"

      # Entity responsible for making contributions to the resource - person, organization or service
      field :contributor, type: String

      # A point or period of time associated with an event in the lifecycle of the resource.
      field :date, type: Date

      # Conforms to DCMI Type Vocabulary - http://dublincore.org/documents/2000/07/11/dcmi-type-vocabulary/
      field :type, type: String, default: "text"

      # Conforms to IANA mime types - http://www.iana.org/assignments/media-types/media-types.xhtml
      field :format, type: String, default: "application/octet-stream"

      # An unambiguous reference to the resource - Conforms to URI
      #TODO remove the defaulted value after migration is successful
      field :identifier, type: String, default: "missing_uri"

      # A related resource from which the described resource is derived
      field :source, type: String, default: "enroll_system"

      # Conforms to ISO 639
      field :language, type: String, default: "en"

      # A related resource - a string conforming to a formal identification system
      field :relation, type: String

      # Spatial (e.g. "District of Columbia") or temporal (e.g. "Open Enrollment 2016") topic of the resource
      field :coverage, type: String

      # Conforms to ACCESS_RIGHTS above
      field :rights, type: String

      field :tags, type: Array, default: []

      validates_presence_of :identifier, :title, :creator, :publisher, :type, :format, :source, :language

      validates :rights,
        allow_blank: true,
        inclusion: { in: ACCESS_RIGHTS, message: "%{value} is not a valid access right" }


      index({identifier: 1})
      index({publisher: 1, title: 1})
      index({publisher: 1, subject: 1})


      scope :by_identifier,    ->(identifier) { where(identifier: identifier) }
      scope :by_publisher,     ->(publisher)  { where(publisher: publisher) }
      scope :by_subject,       ->(subject)    { where(subject: subject) }


    end
  end
end
