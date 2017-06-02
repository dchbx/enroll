# This class is used to store metadata for 1095A tax documents
class TaxDocument < Document

  after_initialize :set_subject

  VERSION_TYPES = ['new', 'corrected', 'void']

  field :version_type, type: String, default: 'new'
  field :hbx_enrollment_id, type: String #policy id
  field :year, type: String

  validates_inclusion_of :version_type, in: VERSION_TYPES
  validates_presence_of :hbx_enrollment_id, :version_type, :year
  validate :valid_year

  private
  def set_subject
    self.subject == '1095A'
  end

  def valid_year
    errors.add(:year, "year should be 4 digits long, e.g. 2016") if year.length != 4
  end
end