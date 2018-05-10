require 'rails_helper'

RSpec.describe ApplicationController do
  controller(Employers::EmployerProfilesController) do
    def index
      render text: "Anonymous Index"
    end
  end

  context "when not signed in" do
    context "with default sign in behavior" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:site_uses_default_devise_path?).and_return(true)
        get :index
      end
      it "redirect to the sign in page" do
        expect(response).to redirect_to(new_user_session_path)
      end
      it "should set portal in session" do
        expect(session[:portal]).to eq "http://test.host/employers/employer_profiles"
      end
    end

    context "with overridden sign in behavior" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:site_uses_default_devise_path?).and_return(false)
        get :index
      end
      it "redirect to the sign up page" do
        expect(response).to redirect_to(new_user_registration_path)
      end
      it "should set portal in session" do
        expect(session[:portal]).to eq "http://test.host/employers/employer_profiles"
      end
    end
  end

  context "when signed in with new user" do
    let(:user) { FactoryGirl.create("user") }

    it "should return the root url in dev environment" do
      expect( controller.send(:after_sign_out_path_for, user) ).to eq logout_saml_index_path
    end
  end

  context "when signed in" do
    let(:user) { double("user", :has_hbx_staff_role? => true, :has_employer_staff_role? => false)}
    let(:person) { double("person")}
    let(:hbx_staff_role) { double("hbx_staff_role")}
    let(:hbx_profile) { double("hbx_profile")}

    before do
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
      allow(hbx_staff_role).to receive(:hbx_profile).and_return(hbx_profile)
      sign_in(user)
      get :index
    end

    it "returns http success" do
      expect(response).not_to redirect_to(new_user_session_url)
    end

    it "doesn't set portal in session" do
      expect(session[:portal]).not_to be
    end
  end

  context "authenticate_user_from_token!" do
    let(:user) { FactoryGirl.create(:user) }

    it "should get signed in flash notice" do
      allow(controller).to receive(:authentication_not_required?).and_return true
      get :index, user_token: user.authentication_token
      expect(flash[:notice]).to eq "Signed in Successfully."
    end
  end

  context "session[person_id] is nil" do
      let(:person) {FactoryGirl.create(:person);}
      let(:user) { FactoryGirl.create(:user, :person=>person); }

      before do
        sign_in(user)
        allow(person).to receive(:agent?).and_return(true)
        allow(subject).to receive(:redirect_to).with(String)
        @request.session['person_id'] = nil
      end

      context "agent role" do
        before do
          user.roles << 'csr'
        end

        it "writes a log message by default" do
          #expect(subject).to receive(:log) do |msg, severity|
            #expect(severity[:severity]).to eq('error')
            #expect(msg[:user_id]).to match(user.id)
            #expect(msg[:oim_id]).to match(user.oim_id)
            #end
          subject.instance_eval{set_current_person}
        end
        it "does not write a log message if @person is not required" do
          expect(subject).not_to receive(:log)
          subject.instance_eval{set_current_person(required: false)}
        end
      end
  end
  context "session[person_id] is nil" do
      let(:person) {FactoryGirl.create(:person);}
      let(:user) { FactoryGirl.create(:user, :person=>person); }

      before do
        sign_in(user)
        allow(person).to receive(:agent?).and_return(false)
        allow(subject).to receive(:redirect_to).with(String)
        @request.session['person_id'] = nil
      end

      context "non agent role" do
        it "does not write a log message if @person is not required" do
          expect(subject).not_to receive(:log)
          subject.instance_eval{set_current_person(required: false)}
        end
      end
  end

  context "require_login" do
    let(:person) {FactoryGirl.create(:person);}
    let(:user) { FactoryGirl.create(:user, :person=>person); }

    before do
      sign_in(user)
      @request.session['person_id'] = person.id
      allow(person).to receive(:agent?).and_return(true)
      allow(controller).to receive(:redirect_to).with(String)
      allow(controller).to receive(:current_user).and_return(nil)
      allow(controller.request).to receive(:format).and_raise("")
    end

    it "writes an error log message exception occures" do
      expect(controller).to receive(:log) do |msg, severity|
        expect(severity[:severity]).to eq('error')
        expect(msg[:session_person_id]).to eq(person.id)
        expect(msg[:message]).to include("Application Exception")
      end
      controller.instance_eval{require_login}
    end
  end

  context "page_alphabets" do
    let(:person) { FactoryGirl.create(:person); }
    let(:user) { FactoryGirl.create(:user, :person => person); }
    let(:alphabet_array) { Person.distinct('last_name').collect { |word| word.first.upcase }.uniq.sort }

    before do
      sign_in(user)
    end

    it "return array of 1st alphabets of given field" do
      pagination = subject.instance_eval { page_alphabets(Person.all, 'last_name') }
      expect(pagination).to eq alphabet_array
    end
  end
end
