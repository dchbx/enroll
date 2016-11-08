require "rails_helper"

describe HandleCoverageSelected do

  let(:context)  do
    { :hbx_enrollment => hbx_enrollment }
  end

  let(:the_hbx_id) { "ALKJFKLJEIJFDLF" }
  let(:the_update_time) { Time.now }


  describe "given an IVL policy with multiple members" do
    let(:hbx_enrollment) { instance_double(HbxEnrollment, :is_shop? => false, :hbx_enrollment_members => enrollment_members, :hbx_id => the_hbx_id) }

    let(:enrollment_member_1) { instance_double(HbxEnrollmentMember) }
    let(:enrollment_member_2) { instance_double(HbxEnrollmentMember) }

    let(:enrollment_members) { [enrollment_member_1, enrollment_member_2] }

    before(:each) do
      allow(enrollment_member_1).to receive(:ivl_coverage_selected)
      allow(enrollment_member_2).to receive(:ivl_coverage_selected)
      allow(Time).to receive(:now).and_return(the_update_time)
      allow(hbx_enrollment).to receive(:update_attributes!).with({:published_to_bus_at => the_update_time})
    end

    it "has a successful result" do
      expect(HandleCoverageSelected.call(context).success?).to be_truthy
    end

    it "notifies of coverage selection for enrollment member 1" do
      expect(enrollment_member_1).to receive(:ivl_coverage_selected).with(no_args)
      HandleCoverageSelected.call(context)
    end

    it "notifies of coverage selection for enrollment member 2" do
      expect(enrollment_member_2).to receive(:ivl_coverage_selected).with(no_args)
      HandleCoverageSelected.call(context)
    end

    it "notifies the bus of a policy creation" do
      expect(ActiveSupport::Notifications).to receive(:instrument).with(HbxEnrollment::ENROLLMENT_CREATED_EVENT_NAME, {policy_id: the_hbx_id})
      HandleCoverageSelected.call(context)
    end

    it "records that the enrollment was transmitted to the bus" do
      expect(hbx_enrollment).to receive(:update_attributes!).with({:published_to_bus_at => the_update_time})
      HandleCoverageSelected.call(context)
    end
  end

  describe "given a SHOP policy with multiple members" do
     let(:hbx_enrollment) { instance_double(HbxEnrollment, :is_shop? => true, :hbx_enrollment_members => enrollment_members, :hbx_id => the_hbx_id, :is_shop_sep? => purchased_in_sep) }

     let(:enrollment_member_1) { instance_double(HbxEnrollmentMember) }
     let(:enrollment_member_2) { instance_double(HbxEnrollmentMember) }

     let(:enrollment_members) { [enrollment_member_1, enrollment_member_2] }

    describe "for open enrollment selection" do
      let(:purchased_in_sep) { false }

      it "has a successful result" do
        expect(HandleCoverageSelected.call(context).success?).to be_truthy
      end

      it "does not notify of ivl coverage selection for enrollment member 1" do
        expect(enrollment_member_1).not_to receive(:ivl_coverage_selected).with(no_args)
        HandleCoverageSelected.call(context)
      end

      it "does not notify of ivl coverage selection for enrollment member 1" do
        expect(enrollment_member_1).not_to receive(:ivl_coverage_selected).with(no_args)
        HandleCoverageSelected.call(context)
      end

      it "does not notify the bus" do
        expect(ActiveSupport::Notifications).not_to receive(:instrument)
        HandleCoverageSelected.call(context)
      end

      it "does not record that the enrollment was transmitted to the bus" do
        expect(hbx_enrollment).not_to receive(:update_attributes!)
        HandleCoverageSelected.call(context)
      end
    end

    describe "for a SEP selection" do
      let(:purchased_in_sep) { true }

      before(:each) do
        allow(Time).to receive(:now).and_return(the_update_time)
        allow(hbx_enrollment).to receive(:update_attributes!).with({:published_to_bus_at => the_update_time})
      end

      it "has a successful result" do
        expect(HandleCoverageSelected.call(context).success?).to be_truthy
      end

      it "does not notify of ivl coverage selection for enrollment member 1" do
        expect(enrollment_member_1).not_to receive(:ivl_coverage_selected)
        HandleCoverageSelected.call(context)
      end

      it "does not notify of ivl coverage selection for enrollment member 1" do
        expect(enrollment_member_2).not_to receive(:ivl_coverage_selected)
        HandleCoverageSelected.call(context)
      end

      it "notifies the bus of a policy updated" do
        expect(ActiveSupport::Notifications).to receive(:instrument).with(HbxEnrollment::ENROLLMENT_CREATED_EVENT_NAME, {policy_id: the_hbx_id})
        HandleCoverageSelected.call(context)
      end

      it "records that the enrollment was transmitted to the bus" do
        expect(hbx_enrollment).to receive(:update_attributes!).with({:published_to_bus_at => the_update_time})
        HandleCoverageSelected.call(context)
      end
    end
  end
end
