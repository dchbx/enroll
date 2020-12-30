module TransportProfiles
  module Processes
    class PushReportEligibilityUpdatedH41 < ::TransportProfiles::Processes::Process

      def initialize(source_uri, gateway, destination_file_name: d_file_name, source_credentials: s_credentials)
        super("Distribute eligibility updated H41", gateway)
        add_step(TransportProfiles::Steps::RouteTo.new(:cms_h41_uploads_archive, source_uri, gateway, destination_file_name: destination_file_name, source_credentials: source_credentials))
        add_step(TransportProfiles::Steps::RouteTo.new(:cms_h41_uploads, source_uri, gateway, destination_file_name: destination_file_name, source_credentials: source_credentials))
      end

      def self.used_endpoints
        [
          :cms_h41_uploads_archive,
          :cms_h41_uploads
        ]
      end
    end
  end
end
