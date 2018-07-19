module BenefitSponsors
  module Forms
    class RosterUploadForm
      include ActiveModel::Validations
      include Virtus.model

      TEMPLATE_DATE = Date.new(2016, 10, 26)
      TEMPLATE_VERSION = "1.1"

      attribute :template_version
      attribute :template_date
      attribute :profile
      attribute :file
      attribute :sheet
      attribute :census_records, Array[Forms::CensusRecordForm]
      attribute :census_titles, Array
      attribute :redirection_url

      validates_presence_of :file, :profile, :template_version, :template_date

      validate :roster_records
      validate :roster_template

      def self.call(file, profile)
        service = resolve_service.new(file: file, profile: profile)
        form = new
        service.load_form_metadata(form)
        form
      end

      def self.resolve_service
        BenefitSponsors::Services::RosterUploadService
      end

      def save
        persist!
      end

      def persist!
        if valid?
          service.save(self)
        end
      end

      def service
        @service ||= self.class.resolve_service.new
      end

      def roster_template
        template_date = parse_date(self.template_date)
        unless (template_date == TEMPLATE_DATE && template_version == TEMPLATE_VERSION && header_valid?(sheet.row(2)))
          self.errors.add(:base, "Unrecognized Employee Census spreadsheet format. Contact #{Settings.site.short_name} for current template.")
          self.redirection_url = "/benefit_sponsors/profiles/employers/employer_profiles/_download_new_template"
        end
      end

      def roster_records
        self.census_records.each_with_index do |census_record, i|
          unless census_record.valid?
            self.errors.add(:base, "Row #{i + 4}: #{census_record.errors.full_messages}")
          end
        end
      end

      def header_valid?(row)
        clean_header = row.reduce([]) { |memo, header_text| memo << sanitize_value(header_text) }
        clean_header == census_titles || clean_header == census_titles[0..-2]
      end

      def parse_date(date)
        if date.is_a? Date
          date
        else
          Date.strptime(date, "%m/%d/%Y")
        end
      end

      def sanitize_value(value)
        value = value.to_s.split('.')[0] if value.is_a? Float
        value.gsub(/[[:cntrl:]]|^[\p{Space}]+|[\p{Space}]+$/, '')
      end
    end
  end
end
