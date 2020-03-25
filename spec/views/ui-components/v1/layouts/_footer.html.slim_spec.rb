require 'rails_helper'

RSpec.describe "_footer.html.slim", :type => :view, dbclean: :after_each  do

  describe "footer content" do
    before :each do
      render "ui-components/v1/layouts/footer.html.slim"
    end

    it "should display email link" do
      expect(rendered).to have_text(Settings.contact_center.email_address)
    end

    it "should display Phone numer" do
      expect(rendered).to have_text(Settings.contact_center.short_number)
    end

    it "should display TTY numer" do
      expect(rendered).to have_text(Settings.contact_center.tty_number)
    end

    it "should display copy-right logo" do
      expect(rendered).to have_selector(:xpath, ".//*[@id='footer-uic']/div/div[2]/div/ul/li[2]/a")

    end

    it "should display envelope logo" do
      expect(rendered).to have_selector(:xpath, "//*[@id='footer-uic']/div/div[2]/div/ul/li[2]/a/span/i")
    end
  end
end
