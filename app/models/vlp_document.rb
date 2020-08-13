class VlpDocument < Document
  include Mongoid::History::Trackable

  attr_accessor :changing_status

  NATURALIZATION_DOCUMENT_TYPES = ["Certificate of Citizenship", "Naturalization Certificate"]

  VLP_DOCUMENT_IDENTIFICATION_KINDS = [
      "Alien Number",
      "I-94 Number",
      "Visa Number",
      "Passport Number",
      "SEVIS ID",
      "Naturalization Number",
      "Receipt Number",
      "Citizenship Number",
      "Card Number"
    ]

  #list of the documents consumer can provide to verify SSN
  SSN_DOCUMENTS_KINDS = ['US Passport', 'Social Security Card',]

  #list of the documents consumer can provide to verify Citizenship
  CITIZENSHIP_DOCUMENTS_KINDS = [
      'US Passport',
      'Social Security Card',
      'Certification of Birth Abroad (issued by the U.S. Department of State Form FS-545)',
      'Original or certified copy of a birth certificate'
  ]

  #list of the documents user can provide to verify Immigration status
  VLP_DOCUMENT_KINDS = [
      "I-327 (Reentry Permit)",
      "I-551 (Permanent Resident Card)",
      "I-571 (Refugee Travel Document)",
      "I-766 (Employment Authorization Card)",
      "Certificate of Citizenship",
      "Naturalization Certificate",
      "Machine Readable Immigrant Visa (with Temporary I-551 Language)",
      "Temporary I-551 Stamp (on passport or I-94)",
      "I-94 (Arrival/Departure Record)",
      "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport",
      "Unexpired Foreign Passport",
      "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)",
      "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)",
      "Other (With Alien Number)",
      "Other (With I-94 Number)"
    ]

    VLP_DOCUMENTS_VERIF_STATUS = ['not submitted', 'downloaded', 'verified', 'rejected']

    COUNTRIES_LIST = [ "Afghanistan", "Albania", "Algeria", "Andorra", "Angola", "Antigua and Barbuda",
    "Argentina", "Armenia", "Australia", "Austria", "Azerbaijan", "Bahamas", "Bahrain", "Bangladesh",
    "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bhutan", "Bolivia", "Bosnia and Herzegovina",
    "Botswana", "Brazil", "Brunei", "Bulgaria", "Burkina Faso", "Burundi", "Cambodia", "Cameroon",
    "Canada", "Cape Verde", "Central African Republic", "Chad", "Chile", "China", "Colombi",
    "Comoros", "Congo (Brazzaville)", "Congo", "Costa Rica", "Cote d'Ivoire", "Croatia", "Cuba",
    "Cyprus", "Czech Republic", "Denmark", "Djibouti", "Dominica", "Dominican Republic", "East Timor (Timor Timur)",
    "Ecuador", "Egypt", "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Ethiopia", "Fiji", "Finland",
    "France", "Gabon", "Gambia, The", "Georgia", "Germany", "Ghana", "Greece", "Grenada", "Guatemala",
    "Guinea", "Guinea-Bissau", "Guyana", "Haiti", "Honduras", "Hungary", "Iceland", "India", "Indonesia",
    "Iran", "Iraq", "Ireland", "Israel", "Italy", "Jamaica", "Japan", "Jordan", "Kazakhstan", "Kenya",
    "Kiribati", "Korea, North", "Korea, South", "Kuwait", "Kyrgyzstan", "Laos", "Latvia", "Lebanon",
    "Lesotho", "Liberia", "Libya", "Liechtenstein", "Lithuania", "Luxembourg", "Macedonia", "Madagascar",
    "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", "Mauritania", "Mauritius",
    "Mexico", "Micronesia", "Moldova", "Monaco", "Mongolia", "Morocco", "Mozambique", "Myanmar",
    "Namibia", "Nauru", "Nepal", "Netherlands", "New Zealand", "Nicaragua", "Niger", "Nigeria", "Norway",
    "Oman", "Pakistan", "Palau", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines",
    "Poland", "Portugal", "Qatar", "Romania", "Russia", "Rwanda", "Saint Kitts and Nevis",
    "Saint Lucia", "Saint Vincent", "Samoa", "San Marino", "Sao Tome and Principe", "Saudi Arabia",
    "Senegal", "Serbia and Montenegro", "Seychelles", "Sierra Leone", "Singapore", "Slovakia",
    "Slovenia", "Solomon Islands", "Somalia", "South Africa", "Spain", "Sri Lanka", "Sudan",
    "Suriname", "Swaziland", "Sweden", "Switzerland", "Syria", "Taiwan", "Tajikistan",
    "Tanzania", "Thailand", "Togo", "Tonga", "Trinidad and Tobago", "Tunisia", "Turkey",
    "Turkmenistan", "Tuvalu", "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom",
    "United States", "Uruguay", "Uzbekistan", "Vanuatu", "Vatican City", "Venezuela", "Vietnam",
    "Yemen", "Zambia","Zimbabwe"
  ]

  # admin action list for verification process, dropdown for each verification type
  ADMIN_VERIFICATION_ACTIONS = ["Verify", "Reject", "View History", "Call HUB", "Extend"]

  # reasons admin can provide when verifying type
  VERIFICATION_REASONS = ["Document in EnrollApp", "Document in DIMS", "SAVE system", "E-Verified in Curam"]

  # reasons admin can provide when rejecting verification type. these reasons applied for all verification types
  ALL_TYPES_REJECT_REASONS = ["Illegible", "Incomplete Doc", "Wrong Type", "Wrong Person"]
  #additionla reasons for citizenship and immigartion verification types
  CITIZEN_IMMIGR_TYPE_ADD_REASONS = ["Expired"]
  #additional reasons for Income verification types WILL BE IMPLEMENTED LATER
  INCOME_TYPE_ADD_REASONS = ["4 weeks", "Too old", "All types"]


  field :alien_number, type: String
  field :i94_number, type: String
  field :visa_number, type: String
  field :passport_number, type: String
  field :sevis_id, type: String
  field :naturalization_number, type: String
  field :receipt_number, type: String
  field :citizenship_number, type: String
  field :card_number, type: String
  field :country_of_citizenship, type: String


  # date of expiration of the document. e.g. passport / documentexpiration date
  field :expiration_date, type: DateTime

  # country which issued the document. e.g. passport issuing country
  field :issuing_country, type: String

  # document verification status ::VlpDocument::VLP_DOCUMENTS_VERIF_STATUS
  field :status, type: String, default: "not submitted"

  # verification type this document can support: Social Security Number, Citizenship, Immigration status, Native American status
  field :verification_type

  field :comment, type: String

  track_history :modifier_field_optional => true,
                :on => [:title,
                        :subject,
                        :alien_number,
                        :i94_number,
                        :visa_number,
                        :passport_number,
                        :sevis_id,
                        :naturalization_number,
                        :receipt_number,
                        :citizenship_number,
                        :card_number,
                        :country_of_citizenship,
                        :expiration_date,
                        :issuing_country,
                        :status,
                        :verification_type,
                        :comment],
                :scope => :consumer_role,
                :track_create => true,
                :track_destroy => true

  scope :uploaded, ->{ where(identifier: {:$exists => true}) }

  validates :alien_number, length: { is: 9 }, :allow_blank => true
  validates :citizenship_number, length: { in: 6..12 }, :allow_blank => true
  validates :i94_number, length: { is: 11 }, :allow_blank => true
  validates :naturalization_number, length: { in: 6..12 }, :allow_blank => true
  validates :passport_number, length: { in: 6..12 }, :allow_blank => true
  validates :sevis_id, length: { is: 10 } , :allow_blank => true #first char is N
  validates :visa_number, length: { is: 8 }, :allow_blank => true
  validates :receipt_number, length: { is: 13}, :allow_blank => true #first 3 alpha, remaining 10 string
  validates :card_number, length: { is: 13 }, :allow_blank => true#first 3 alpha, remaining 10 numeric

  # hash of doc type and necessary fields
  def required_fields
    {
        "I-327 (Reentry Permit)":[:alien_number],
        "I-551 (Permanent Resident Card)": [:alien_number, :card_number],
        "I-571 (Refugee Travel Document)": [:alien_number],
        "I-766 (Employment Authorization Card)": [:alien_number, :card_number, :expiration_date],
        "Certificate of Citizenship": [:citizenship_number],
        "Naturalization Certificate": [:naturalization_number],
        "Machine Readable Immigrant Visa (with Temporary I-551 Language)": [:alien_number, :passport_number],
        "Temporary I-551 Stamp (on passport or I-94)": [:alien_number],
        "I-94 (Arrival/Departure Record)": [:i94_number],
        "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport": [:i94_number, :passport_number, :expiration_date],
        "Unexpired Foreign Passport": [:passport_number, :expiration_date],
        "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)": [:sevis_id],
        "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)": [:sevis_id],
        "Other (With Alien Number)": [:alien_number, :description],
        "Other (With I-94 Number)": [:i94_number, :description]
    }
  end

  def self.immigration_document_types
    options = []
    VLP_DOCUMENT_KINDS.each do |document|
      options << [self.document_types_to_display[document], document]
    end

    options
  end

  def self.document_types_to_display
    {
      'I-327 (Reentry Permit)' => 'I-327 – Reentry permit',
      'I-551 (Permanent Resident Card)' => 'I-551 – Permanent resident card',
      'I-571 (Refugee Travel Document)' => 'I-571 – Refugee travel document',
      'I-766 (Employment Authorization Card)' => 'I-766 – Employment authorization card',
      'Certificate of Citizenship' => 'Certificate of citizenship',
      'Naturalization Certificate' => 'Naturalization certificate',
      'Machine Readable Immigrant Visa (with Temporary I-551 Language)' => 'Machine-readable immigrant visa (with temporary I-551 language)',
      'Temporary I-551 Stamp (on passport or I-94)' => 'Temporary I-551 stamp (on passport or I-94)',
      'I-94 (Arrival/Departure Record)' => 'I-94 – Arrival/departure record',
      'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport' => 'I-94 – Arrival/departure record in unexpired foreign passport',
      'Unexpired Foreign Passport' => 'Unexpired foreign passport',
      'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)' => 'I-20 – Certificate of eligibility for nonimmigrant student (F-1) status',
      'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)' => 'DS-2019 Certificate of eligibility for exchange visitor (J-1) status',
      'Other (With Alien Number)' => 'Other (with alien number)',
      'Other (With I-94 Number)' => 'Other (with I-94 number)'
    }
  end

  private
  def document_required_fields
     required_fields[self.subject.to_sym].each do |field|
       errors.add(:base, "#{field} value is required") unless self.send(field).present?
     end
  end
   
end
