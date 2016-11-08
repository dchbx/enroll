class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person
  embedded_in :office_location
  embedded_in :census_member, class_name: "CensusMember"

  KINDS = %W(home work mailing)
  OFFICE_KINDS = %W(primary mailing branch)

  field :kind, type: String
  field :address_1, type: String
  field :address_2, type: String, default: ""
  field :address_3, type: String, default: ""
  field :city, type: String
  field :county, type: String
  field :state, type: String
  field :location_state_code, type: String
  field :zip, type: String
  field :country_name, type: String, default: ""
  field :full_text, type: String

  validates_presence_of :address_1, :city, :state, :zip

  validates :kind,
    inclusion: { in: KINDS + OFFICE_KINDS, message: "%{value} is not a valid address kind" },
    allow_blank: false

  validates :zip,
    format: {
        :with => /\A\d{5}(-\d{4})?\z/,
        :message => "should be in the form: 12345 or 12345-1234"
      }

  def location
    nil #todo
  end

  def blank?
    [:city, :zip, :address_1, :address_2].all? do |attr|
      self.send(attr).blank?
    end
  end

  def to_html
    if address_2.blank?
      "<div>#{address_1.strip()}</div><div>#{city}, #{state} #{zip}</div>".html_safe
    else
      "<div>#{address_1.strip()}</div><div>#{address_2}</div><div>#{city}, #{state} #{zip}</div>".html_safe
    end
  end

  def to_s
    city.present? ? city_delim = city + "," : city_delim = city
    line3 = [city_delim, state, zip].reject(&:nil? || empty?).join(' ')
    [address_1, address_2, line3].reject(&:nil? || empty?).join('<br/>').html_safe
  end

  def full_address
    city.present? ? city_delim = city + "," : city_delim = city
    [address_1, address_2, city_delim, state, zip].reject(&:nil? || empty?).join(' ')
  end

  def kind=(new_kind)
    kind_val = new_kind.to_s.squish.downcase
    if kind_val == 'primary' && office_location.present? && office_location.is_primary
      write_attribute(:kind, 'work')
    else
      write_attribute(:kind, kind_val)
    end
  end

  def kind
    kind_val = read_attribute(:kind)
    if office_location.present? && office_location.is_primary && kind_val == 'work'
      'primary'
    else
      kind_val
    end
  end

  def address_1=(new_address_1)
    write_attribute(:address_1, new_address_1.to_s.squish)
  end

  def address_2=(new_address_2)
    write_attribute(:address_2, new_address_2.to_s.squish)
  end

  def address_3=(new_address_3)
    write_attribute(:address_3, new_address_3.to_s.squish)
  end

  def city=(new_city)
    write_attribute(:city, new_city.to_s.squish)
  end

  def state=(new_state)
    write_attribute(:state, new_state.to_s.squish)
  end

  def zip=(new_zip)
    write_attribute(:zip, new_zip.to_s.squish)
  end

  def zip_without_extension
    return nil if zip.blank?
    if zip =~ /-/
      zip.split("-").first
    else
      zip
    end
  end

  def zip_extension
    return nil if zip.blank?
    if zip =~ /-/
      zip.split("-").last
    else
      nil
    end
  end

  def home?
    "home" == self.kind.to_s
  end

  def matches?(another_address)
    return(false) if another_address.nil?
    attrs_to_match = [:kind, :address_1, :address_2, :address_3, :city, :state, :zip]
    attrs_to_match.all? { |attr| attribute_matches?(attr, another_address) }
  end

  def attribute_matches?(attribute, other)
    self[attribute].to_s.downcase == other[attribute].to_s.downcase
  end
end
