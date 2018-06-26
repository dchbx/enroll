require 'curl'

module Notifier
  class NoticeKind
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include Notifier::NoticeBuilder

    RECIPIENTS = {
      "Employer" => "Notifier::MergeDataModels::EmployerProfile",
      "Employee" => "Notifier::MergeDataModels::EmployeeProfile",
      "Broker" => "Notifier::MergeDataModels::BrokerProfile",
      "Broker Agency" => "Notifier::MergeDataModels::BrokerAgencyProfile",
      "GeneralAgency" => "Notifier::MergeDataModels::GeneralAgency"
    }

    field :title, type: String
    field :description, type: String
    field :identifier, type: String
    field :notice_number, type: String
    field :recipient, type: String, default: "Notifier::MergeDataModels::EmployerProfile"
    field :aasm_state, type: String, default: :draft
    field :event_name, type: String, default: nil

    embeds_one :cover_page
    embeds_one :template, class_name: "Notifier::Template"
    embeds_many :workflow_state_transitions, as: :transitional

    validates_presence_of :title, :notice_number, :recipient
    validates_uniqueness_of :notice_number
    validates_uniqueness_of :event_name, :allow_blank => true

    before_save :set_data_elements

    scope :published,         ->{ any_in(aasm_state: ['published']) }
    scope :archived,          ->{ any_in(aasm_state: ['archived']) }

    attr_accessor :resource, :payload


    def tokens
      template.raw_body.scan(/\#\{([\w|\.|\s|\+|\-]*)\}/).flatten.reject{|element| element.scan(/Settings/).any?}.uniq.map(&:strip)
    end

    def conditional_tokens
      template.raw_body.scan(/\[\[([\s|\w|\.|?]*)/).flatten.map(&:strip).collect{|ele| ele.gsub(/if|else|end|else if|elsif/i, '')}.map(&:strip).reject{|elem| elem.blank?}.uniq
    end

    def set_data_elements
      if template.present?
        conditional_token_loops = []
        iterator_subloop_tokens = []
        loop_tokens = []
        loop_iterators = conditional_tokens.inject([]) do |iterators, conditional_token|
          iterators unless conditional_token.match(/(.+)\.each/i)
          loop_match = conditional_token.match(/\|(.+)\|/i)
          if loop_match.present?
            loop_token = conditional_token.match(/(.+)\.each/i)[1]
            loop_tokens << loop_token
            iterator_subloop_tokens << loop_token if iterators.any?{|iterator| loop_token.match(/^#{iterator}\.(.*)$/i).present? }
            conditional_token_loops << conditional_token
            iterators << loop_match[1].strip
          else
            iterators
          end
        end

        filtered_conditional_tokens = conditional_tokens - conditional_token_loops
        data_elements = (tokens + filtered_conditional_tokens + loop_tokens).reject{|token| loop_iterators.any?{|iterator| token.match(/^#{iterator}\.(.*)$/i).present? && token.match(/(.+)\.each/i).blank?} }
        template.data_elements = data_elements + iterator_subloop_tokens
      end
    end

    def execute_notice(event_name, payload)
      finder_mapping = Notifier::ApplicationEventMapper.lookup_resource_mapping(event_name)
      if finder_mapping.nil?
        raise ArgumentError.new("BOGUS EVENT...could n't find resoure mapping for event #{event_name}.")
      end
      @payload = payload
      @resource = finder_mapping.mapped_class.send(finder_mapping.search_method, payload[finder_mapping.identifier_key.to_s])
      if @resource.blank?
        raise ArgumentError.new("Bad Payload...could n't find resoure with #{payload[finder_mapping.identifier_key.to_s]}.")
      end
      generate_pdf_notice
      upload_and_send_secure_message
      send_generic_notice_alert
      send_generic_notice_alert_to_broker
    end

    def recipient_klass_name
      recipient.to_s.split('::').last.underscore.to_sym
    end

    def self.to_csv
      CSV.generate(headers: true) do |csv|
        csv << ['Notice Number', 'Title', 'Description', 'Recipient', 'Event Name', 'Notice Template']

        all.each do |notice|
          csv << [notice.notice_number, notice.title, notice.description, notice.recipient, notice.event_name, notice.template.try(:raw_body)]
        end
      end
    end

    aasm do
      state :draft, initial: true

      state :published
      state :archived

      event :publish, :after => :record_transition do
        transitions from: :draft,  to: :published,  :guard  => :can_be_published?
      end

      event :archive, :after => :record_transition do
        transitions from: [:published],  to: :archived
      end  
    end

    # Check if notice with same MPI indictor exists
    def can_be_published?
    end

    def record_transition
      self.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: aasm.from_state,
        to_state: aasm.to_state
        )
    end

    # def self.markdown
    #   Redcarpet::Markdown.new(ReplaceTokenRenderer,
    #       no_links: true,
    #       hard_wrap: true,
    #       disable_indented_code_blocks: true,
    #       fenced_code_blocks: false,        
    #     )
    # end

    # # Markdown API: http://www.rubydoc.info/gems/redcarpet/3.3.4
    # def to_html
    #   self.markdown.render(template.body)
    # end
  end
end
