RSpec.describe Notifier::EnrollmentHelper, :type => :helper do
  let!(:hbx_enrollment)  do
    double(
      coverage_start_on: "",
      premium_amount: "",
      product: double(
        application_period: (Date.today..(Date.today + 1.week)),
        title: "Product Title",
        metal_level_kind: "bronze",
        kind: "health",
        issuer_profile: double(legal_name: "Legal Name"),
        hsa_eligibility: "",
        deductible: "",
        family_deductible: ""
      ),
      dependents: "",
      kind: "",
      enrolled_count: "",
      enrollment_kind: "",
      coverage_kind: "",
      aptc_amount: "",
      is_receiving_assistance: "",
      responsible_amount: "",
      effective_on: "",
      total_premium: 10,
      hbx_enrollment_members: [],
      applied_aptc_amount: 1
    )
  end

  context "#enrollment_hash" do
    it "should return a MergeDataModels::Enrollment when enrollment is passed through" do
      expect(helper.enrollment_hash(hbx_enrollment).class).to eq(Notifier::MergeDataModels::Enrollment)
    end
  end

  context "#is_receiving_assistance?" do
    let(:hbx_enrollment1) do
      double(
        applied_aptc_amount: 1,
        product: double(is_csr?: true)
      )
    end

    it "should return a boolean" do
      expect(helper.is_receiving_assistance?(hbx_enrollment1)).to eq(true)
    end
  end

  context "#responsible_amount" do
    it "should return the amount" do
      expect(helper.responsible_amount(hbx_enrollment)).to eq("$9.00")
    end
  end
end
