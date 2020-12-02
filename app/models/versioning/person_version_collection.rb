module Versioning
  class PersonVersionCollection < VersionCollection

    def has_non_curam_determination?
      versions.any? do |v|
        not_authorized_by_curam?(v.resolve_to_model)
      end
    end

    protected
    def not_authorized_by_curam?(person)
      cr = person.consumer_role
      return true if cr.blank?
      lpd = cr.lawful_presence_determination
      return true if lpd.blank?
      !(lpd.vlp_authority == "curam")
    end
  end
end