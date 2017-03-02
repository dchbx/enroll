class ShopNotices::RenewalEmployerEligibilityNotice < ShopNotice

  attr_accessor :employer_profile

  def deliver
    build
    super
  end

end 
