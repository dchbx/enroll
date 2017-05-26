class ShopEmployerNotices::RenewalEmployerEligibilityNotice < ShopEmployerNotice

  attr_accessor :employer_profile

  def deliver
    build
    super
  end

end 
