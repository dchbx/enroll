class PaperApplication < Document

  field :aws_key_id, type: String
  field :status, type: String, default: "not submitted"

  embedded_in :resident_role

  index({ aws_key_id: 1})

  scope :uploaded, ->{ where(identifier: {:$exists => true}) }

end
