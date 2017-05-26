class ShopEmployerNotices::BrokerNotice < ShopEmployerNotice

  def initialize(broker, args = {})
    super(args)
    @broker = broker
    @to = @broker.try(:person).try(:home_email).try(:address)
    @template = args[:template] || "notices/shop_employer_notices/1b_broker_notice.html.erb"
    build
  end

  def deliver
    super
  end

  def build
    @notice = PdfTemplates::BrokerNotice.new
    @notice.first_name = @broker.person.first_name.titleize
    @notice.last_name = @broker.person.last_name.titleize
    @notice.primary_identifier = @broker.hbx_id
    address = (@broker.person.mailing_address.present? ? @broker.person.mailing_address : @broker.address)
    append_primary_address(address)
    append_hbe
  end


end 
