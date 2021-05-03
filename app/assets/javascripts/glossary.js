// page:change accounts for turbolinks affecting JS on document ready
// ajax:success accounts for glossary terms in consumer forms after document ready
// Rails 5 event: 'turbolinks:load' instead of 'page:change'
$(document).on("turbolinks:load ajax:success", function() {
  runGlossary();

  // Added for partials loaded after turbolinks load
  $('.close-2').click(function(e){
    $(document).ajaxComplete(function() {
      runGlossary();
    });
  });
});

/* March 2020 TODO List:
Much of the tooltips in the application live within a Javascript file called glossary.js.
Until we do some refactoring, these links can't reference anything in settings or Resource Registry, and even if and when we do it, we'll still need the links.
Here's the ones we need. Soome of the tooltips in the glosssary hold multiple links, so it isn't just a 1 to ratio of tooltips vs definitions sneeded
1) Affordable Care Act
2) Covered services
3) Advanced Premium Tax Credit
4) Premiums
5) Deductibles
6) Co paymentss
7) Out of pocket limits
8) Bronze, Silver, Gold, Platinum
9) Private Health Insurance
10) Financial Assistance
11) Minimum Essential Coverage
12) Houseshold
13) Minimum Value Standards
14) Advanced Premium Tax Credit
15) Broker
16) Federally Recognized Tribe
17) Indian Health Service
18) Service Providers
19) In network
20) Alaska Native
21) Plan Documents
22) File An Appeal
23) Allowed limits
24) Prescription Drugs
25) Medicaid
26) Medicare
27) Children's Health Insurance Program
28) U.S. Department of Health and Human Services
29) Plan Types
30) Health Insurance
31) Exemptions (Essential Health Benefits)
32) Primary Care
33) Preventative Services
34) Center for Medicare & Medicaid Services<
35) COBRA
36) Department of Insurance, Securities and Banking
37) Cosmetic Surgery/Plasstic Surgery
38) Cover All/DC Healthcare Alliance Program (if Maine has an equivalent)
39) Summary of Benefits and Coverage
40) Dental Plan
41) Maine Health Exchange Authority (If Maine has one)
42) Department of Disability Services
43) State Child Health Insurance Program, and Medical Charities (if it exists in Maine)
44) DHS assistance programs
45) Department of Insurance, Securities and Banking
46) Dependent
47) Department of Health Care Finance
48) Department of Human Services
49) Disability
50) Drug Formulary
51) Domestic Partnership
52) Durable Medical Equipment
53) Employer Shared Responsibility Provision
54) Exclusive Provider Organization
55) Early and Periodic Screening, Diagnostic, and Treatment
56) Health insurance Marketplace
57) Primary Care Physician
58) IRS Form 8965
59) Alaskan Native
60) Supplemental Nutrition Assistance Program
61) Federally Qualified Health Center
62) Federal Poverty Level
63) Plan Participants
64) Brand Name Drug
65) Home and Community-Based Services
66) High Deductible Health Plan
67) IRS Form 1095
68) HIPAA - Health Insurance Portability and Accountability Act
69) Health Reimbursement Account
70) In Patient Care
71) Health Savings Account
72) Immigrant Children's Program (if it exists in Maine)
73) Cost Sharing Reductions
74) individual shared responsibility payment
75) IRS Form 1095-A
76) IRS Form 1095-B
77) CHIP
78) eligibility for the Katie Beckett Program
79) Special Enrollment Period
80) Qualifying Life Event
81) Modified Adjusted Gross Income (MAGI)
82) Long Term Care
83) Social Security Administration
84) State Continuation Coverage
85) Social Security
86) Qualified Health Plan
87) Allowed Amount
88) Balance Billing
89) Reconstructive Surgery
90) Referral
91) Preferred Provider Organization
92) Pre Authorization
93) Qualified Health Plan
94) Department of Insurance, Security & Banking
95) Refugee Cash Assistance Program
96) Small Business Health Options Program
97) Second Lowest Cost Silver Plan
98) Small Business Credit
99) Specialist
100) Temporary Cash Assistance for Needy Families
101) UCR - Usual Customary and Reasonable
*/


function runGlossary() {
  if ($('.run-glossary').length) {
    // Certain glossary terms have been rearranged to avoid a smaller word being given a popover instead of the
    // full glossary term (e.g. Premium/ Premium Tax Credit)
    var terms = [
      {
        "term": "ACA",
        "description": "The acronym for the <a href='https://www.healthcare.gov/glossary/affordable-care-act/' target='_blank'>Affordable Care Act<\/a>."
      },
      {
        "term": "Accreditation",
        "description": "All health plans available through Maine Cover ME have been reviewed by an independent, third-party organization to validate (accredit) that the plans meet quality standards required by the <a href='https://www.healthcare.gov/glossary/affordable-care-act/' target='_blank'>Affordable Care Act<\/a> and the State of Maine."
      },
      {
        "term": "Actuarial Value",
        "description": "A measurement of the average amount each plan will pay for all people enrolled in a plan (not just you) towards out-of-pocket costs for <a href='/glossary#covered_services' target='_blank'>covered services<\/a>. Since it\u2019s an average for all people, your out-of-pocket costs could be higher or lower depending on your health care usage; how other costs like your <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premium<\/a>, <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductible<\/a>, <a href='/glossary#copayment' target='_blank'>copayments<\/a>, <a href='/glossary#coinsurance' target='_blank'>coinsurance<\/a> and <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a> are structured in your plan; and other terms of your insurance policy. <a href='/glossary#bronze_health_plan' target='_blank'>Bronze<\/a> means the plan is expected to pay 60 percent of in-network expenses for an average population of consumers, <a href='/glossary#silver_health_plan' target='_blank'>Silver<\/a> 70 percent, <a href='/glossary#gold_health_plan' target='_blank'>Gold<\/a> 80 percent and <a href='/glossary#platinum_health_plan' target='_blank'>Platinum<\/a> 90 percent."
      },
      {
        "term": "Advance Premium Tax Credit",
        "description": "The federal government offers a tax credit to help pay for private <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> for individuals and families within certain income limits who also meet certain other requirements. The tax credit can either be automatically applied towards your insurance <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> to lower your monthly payment, or you can claim it when you file your federal tax return. You must apply for <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a> to confirm eligibility and to receive the tax credit."
      },
      {
        "term": "Affordable Care Act",
        "description": "The name used to refer to the federal health laws that require most Americans to have <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> that provides <a href='/glossary#minimum_essential_coverage' target='_blank'>Minimum Essential Coverage<\/a>. The name refers to two distinct pieces of legislation \u2014 the Patient Protection and Affordable Care Act (P.L. 111-148) and the Health Care and Education Reconciliation Act of 2010 (P.L. 111-152)."
      },
      {
        "term": "Affordable Coverage",
        "description": "A standard applied to <a href='/glossary#employer-sponsored_health_insurance' target='_blank'>employer-sponsored health plans<\/a>. If you and any members of your <a href='/glossary#household' target='_blank'>household<\/a> are eligible to sign up for employer-sponsored coverage that meets the federal government's affordability and <a href='/glossary#minimum_value' target='_blank'>minimum value<\/a> standards, you won't be eligible for an <a href='/glossary#advance_premium_tax_credit' target='_blank'>advance premium tax credit<\/a> to help pay for <a href='/glossary#private_health_insurance' target='_blank'>private health insurance<\/a> if you decide to enroll through Maine Cover ME's Individual & Family marketplace instead. If the annual <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premium<\/a> to only cover you on a plan offered by your employer is less than approximately 10 percent of your household income, the plan is considered affordable. If you're not sure, you should apply for <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a> through Maine Cover ME to get a decision before declining employer coverage, and to find out if you have other options."
      },
      {
        "term": "Age",
        "description": "Your age is used to determine monthly <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> for insurance."
      },
      {
        "term": "Aged, Blind and Disabled Program",
        "description": "Learn more about <a class='ext' href='http:\/\/dhcf.dc.gov\/service\/aged-blind-disabled' target='_blank'>DC Medicaid eligibility for the aged, blind or disabled<\/a>."
      },
      {
        "term": "Agent",
        "description": "Another word for a <a href='/glossary#broker' target='_blank'>Broker<\/a>."
      },
      {
        "term": "Alaska Native",
        "description": "Alaska Native Claims Settlement Act (ANCSA) corporation shareholders, members of <a href='/glossary#federally_recognized_tribe' target='_blank'>federally recognized Tribes<\/a>, or those eligible for services from the <a href='https://www.ihs.gov/findhealthcare/' target='_blank'>Indian Health Service<\/a>, Tribal Program, or Urban Indian Health Program, are eligible for enhanced savings, benefits and protections through Maine Cover ME. Apply for <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a> prior to enrolling in a health plan to determine eligibility for the savings, benefits and protections available."
      },
      {
        "term": "Allowed Amount",
        "description": "The maximum amount your <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> company will pay service providers for <a href='/glossary#covered_services' target='_blank'>covered services<\/a>. Sometimes this is called an eligible expense, a payment allowance or negotiated rate. <a href='/glossary#service_provider' target='_blank'>Service providers<\/a> that are <a href='/glossary#in-network' target='_blank'>in-network<\/a> with your insurance company have generally agreed to accept the allowed amount for covered services."
      },
      {
        "term": "Ambulatory Patient Services",
        "description": "Care you get without being admitted to a hospital. Examples include but aren't limited to: <a href='/glossary#outpatient_care' target='_blank'>outpatient care<\/a>, <a href='/glossary#home_health_care' target='_blank'>home health care<\/a>, care in an emergency room and pre-admission testing."
      },
      {
        "term": "American Indian",
        "description": "American Indians, members of <a href='/glossary#federally_recognized_tribe' target='_blank'>federally recognized Tribes<\/a>, <a href='/glossary#alaskan_native' target='_blank'>Alaska Native<\/a> Claims Settlement Act (ANCSA) corporation shareholders, and those eligible for services from the <a href='https://www.ihs.gov/findhealthcare/' target='_blank'>Indian Health Service<\/a>, Tribal Program, or Urban Indian Health Program are eligible for enhanced savings, benefits and protections through Maine Cover ME. Apply for <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a> prior to choosing a health plan to determine eligibility and the savings, benefits and protections available."
      },
      {
        "term": "Annual Limit",
        "description": "Some <a href='/glossary#covered_services' target='_blank'>covered services<\/a> in your health plan may have a cost limit on what your insurance company will pay annually for certain benefits or the number of visits for a particular service. If you reach the annual limit, you\u2019ll have to pay for any additional services or visits that apply to the limit. You can find information on annual limits in your <a href='/glossary#plan_documents' target='_blank'>plan documents<\/a>."
      },
      {
        "term": "Appeal",
        "description": "If you don\u2019t agree with a decision about your eligibility for enrollment in coverage, or assistance in paying for coverage, you have a right to appeal the decision and receive a hearing before an independent administrative law judge. Go to the Maine Cover ME Help page and select <a class='ext' href='https:\/\/dchealthlink.com\/help' target='_blank'>'file an appeal'<\/a> to learn more about your rights."
      },
      {
        "term": "Application ID",
        "description": "If you apply for <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a>, you'll be assigned an Application ID when you submit your application. Once you find out if you o\ufb03cially qualify for financial assistance, you'll need your Application ID to continue and complete your enrollment. If you're getting help with your application through Maine Cover ME's Call Center or an Enrollment Center, you'll also need your Application ID."
      },
      {
        "term": "APTC",
        "description": "The acronym for <a href='/glossary#advance_premium_tax_credit' target='_blank'>Advance Premium Tax Credit<\/a>."
      },
      {
        "term": "Assister",
        "description": "Assisters provide in-person help to individuals, families, and small businesses shopping for health plans through Maine Cover ME. Assisters have been trained by Maine Cover ME and are required to provide fair and impartial information to help with eligibility, and facilitate enrollment in health plans. There is no cost to use an Assister."
      },
      {
        "term": "Attestation",
        "description": "When you submit an application through Maine Cover ME, you acknowledge (attest) with an electronic signature that the information you provided is the truth, and that you are authorized to act on behalf of everyone listed on the application."
      },
      {
        "term": "Authorized Representative",
        "description": "Someone you choose to act on your behalf. The person could be a family member, a <a href='/glossary#broker' target='_blank'>Broker<\/a> or other person you trust, or someone who has legal authority to act on your behalf."
      },
      {
        "term": "Balance Billing",
        "description": "If your plan allows you to use <a href='/glossary#out-of-network' target='_blank'>out-of-network<\/a> <a href='/glossary#service_provider' target='_blank'>service providers<\/a>, the plan may choose to only pay the <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a> they pay <a href='/glossary#in-network' target='_blank'>in-network<\/a> service providers. This might be much less than the provider actually charges. You could be responsible for paying the difference between the allowed amount and actual charges even when it exceeds your <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a>. This is called balance billing. If you're having a procedure that involves multiple providers, confirm with your primary doctor and hospital whether or not all the services will be provided by in-network providers. If you know you plan to use an out-of-network service provider, you may want to confirm costs in advance of the visit or procedure so you'll understand how much you'll have to pay, or have the opportunity to negotiate costs."
      },
      {
        "term": "Benefit Year",
        "description": "If you sign up for <a href='/glossary#individual_&_family_health_insurance' target='_blank'>Individual & Family health insurance<\/a> through Maine Cover ME, the benefit year is the year when coverage is active. It begins on January 1 and ends on December 31, even if your coverage starts after January 1. Changes to <a href='/glossary#covered_services' target='_blank'>covered services<\/a> or what you pay for health insurance are made at the beginning of the calendar year. If you sign up for <a href='/glossary#employer-sponsored_health_insurance' target='_blank'>employer-sponsored coverage<\/a> through Maine Cover ME, the benefit year begins when your coverage goes into effect and ends when your entire group\u2019s benefit year ends, even if you started after your group started. Changes to covered services or what you pay for health insurance are made at the beginning of the calendar year."
      },
      {
        "term": "Benefits",
        "description": "Another word for <a href='/glossary#covered_services' target='_blank'>covered services<\/a>."
      },
      {
        "term": "Brand Name Drug",
        "description": "A <a href='/glossary#prescription_drugs' target='_blank'>prescription drug<\/a> or over-the-counter medicine that is protected by a patent and is sold by one company under a specific name or trademark."
      },
      {
        "term": "Breast and Cervical Cancer Program",
        "description": "Maine <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a> may cover individuals diagnosed with breast or cervical cancers who are in need of treatment. Learn more about <a class='ext' href='http:\/\/dhcf.dc.gov\/service\/medicaid-breast-and-cervical-cancer-patients' target='_blank'>Breast and Cervical Cancer Programs in the State of Maine<\/a>."
      },
      {
        "term": "Broker",
        "description": "Brokers are licensed under Maine law to sell <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> through Maine Cover ME to individuals, families, small businesses and their employees. Brokers have been trained by Maine Cover ME, can recommend plans or <a href='/glossary#plan_type' target='_blank'>plan types<\/a>, and perform activities on behalf of their clients as part of their professional licensing and training. There is no cost to use a Broker."
      },
      {
        "term": "Bronze Health Plan",
        "description": "Bronze Health Plans pay about 60 percent of <a href='/glossary#in-network' target='_blank'>in-network<\/a> expenses for an average population of consumers. The <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> are typically among the lowest but the <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductible<\/a> and <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a> of what you'll pay before the plan starts paying are among the highest. <a href='/glossary#metal_level' target='_blank'>Metal levels<\/a> only focus on what the plan is expected to pay, and do NOT reflect the quality of health care or <a href='/glossary#service_provider' target='_blank'>service providers<\/a> available through the <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan. Once you meet your in-network out-of-pocket limit for the <a href='/glossary#plan_year' target='_blank'>plan year<\/a>, plans pay 100 percent of the <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a> for <a href='/glossary#covered_services' target='_blank'>covered services<\/a>."
      },
      {
        "term": "Carrier",
        "description": "An insurance company."
      },
      {
        "term": "Catastrophic Health Plan",
        "description": "A health plan with low monthly <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> and high annual <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductibles<\/a> designed to protect consumers from worst case situations like a serious illness or an accident. Catastrophic plans are only available to people under 30 or people with a hardship <a href='/glossary#exemption' target='_blank'>exemption<\/a>. Catastrophic plans provide <a href='/glossary#essential_health_benefits' target='_blank'>essential health benefits<\/a> and count as having coverage for tax purposes. Plans cover at least 3 <a href='/glossary#primary_care' target='_blank'>primary care<\/a> visits during the <a href='/glossary#plan_year' target='_blank'>plan year<\/a> and certain <a href='/glossary#preventive_services' target='_blank'>preventive services<\/a> at no cost. Consumers pay all other medical costs until the annual deductible is met. Then the plan pays 100 percent for <a href='/glossary#covered_services' target='_blank'>covered services<\/a> for the rest of the plan year. <a href='/glossary#advance_premium_tax_credit' target='_blank'>Advance premium tax credits<\/a> and <a href='/glossary#cost-sharing_reduction' target='_blank'>cost-sharing reductions<\/a> can\u2019t be used with this <a href='/glossary#plan_type' target='_blank'>plan type<\/a>."
      },
      {
        "term": "Center for Medicare and Medicaid Services",
        "description": "An operating division of the <a href='/glossary#us_department_of_health_and_human_services' target='_blank'>U.S. Department of Health and Human Services<\/a> that administers <a href='https://www.medicare.gov/' target='_blank'>Medicare<\/a>, <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a>, the <a href='/glossary#children&#39;s_health_insurance_program' target='_blank'>Children's Health Insurance Program<\/a>, and parts of the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>."
      },
      {
        "term": "Children\u2019s Health Insurance Program",
        "description": "An insurance program that provides no cost or low cost health coverage to children in families that earn too much money to qualify for Medicaid but not enough to buy private health insurance. In the State of Maine, you can apply for CHIP coverage any time of the year through the <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a> program."
      },
      {
        "term": "CHIP",
        "description": "The acronym for the <a href='/glossary#children&#39;s_health_insurance_program' target='_blank'>Children\u2019s Health Insurance Program<\/a>."
      },
      {
        "term": "Claim",
        "description": "A request for payment submitted by you or your <a href='/glossary#service_provider' target='_blank'>service provider<\/a> to your insurance company for <a href='/glossary#covered_services' target='_blank'>covered services<\/a> received or rendered."
      },
      {
        "term": "CMS",
        "description": "The acronym for the <a href='/glossary#center_for_medicare_and_medicaid_services' target='_blank'>Center for Medicare & Medicaid Services<\/a>."
      },
      {
        "term": "COBRA",
        "description": "The acronym for the Consolidated Omnibus Budget Reconciliation Act \u2014 a federal law that may allow you to keep <a href='/glossary#employer-sponsored_health_insurance' target='_blank'>employer-sponsored health insurance<\/a> if you lose your job. In most cases, you'll pay the full costs every month plus a small administrative fee if you elect to continue the coverage. COBRA coverage is typically available up to 18 months (longer only in special circumstances). You may want to compare the cost of continuing your COBRA coverage with <a href='/glossary#private_health_insurance' target='_blank'>private health plans<\/a> available through Maine Cover ME. If you live in the State of Maine and leave your job for any reason, you have 60 days from the date you lost coverage to either enroll in COBRA (if eligible) or sign up for a private plan through Maine Cover ME. However, if you enroll in a COBRA plan, and then voluntarily drop it, or stop paying the <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a>, you can\u2019t enroll in a private plan through Maine Cover ME until the next annual <a href='/glossary#open_enrollment' target='_blank'>open enrollment<\/a>."
      },
      {
        "term": "Coinsurance",
        "description": "Your share of the costs for <a href='/glossary#covered_services' target='_blank'>covered services<\/a> that you pay when you receive them. Coinsurance is calculated as a percent of the total fee. For example, if your <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan\u2019s <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a> to visit your doctor is $100, a coinsurance payment of 20 percent would be $20. Some plans require that you pay up to the plan's <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductible<\/a> amount before coinsurance begins. Once you reach your <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a>, you no longer have to pay coinsurance for the rest of the <a href='/glossary#plan_year' target='_blank'>plan year<\/a>."
      },
      {
        "term": "Complaint",
        "description": "If you have a complaint about your insurance company, or were denied services that you believe qualify as a <a href='/glossary#covered_services' target='_blank'>covered service<\/a>, you have the right to file a complaint with the <a href='/glossary#department_of_insurance&#44;_securities_and_banking' target='_blank'>Department of Insurance, Securities and Banking<\/a>. Learn <a class='ext' href='https:\/\/dchealthlink.com\/file-complaint' target='_blank'>how to file a complaint<\/a>."
      },
      {
        "term": "Consolidated Omnibus Budget Reconciliation Act",
        "description": "A federal law more commonly referred to as <a href='https://www.maine.gov/pfr/insurance/glossary.html#c' target='_blank'>COBRA<\/a>."
      },
      {
        "term": "Consumers' CHECKBOOK",
        "description": "An independent, non-profit consumer authority that powers Maine Cover ME's <a href='/glossary#plan_match' target='_blank'>Plan Match<\/a> comparison tool, Prescription Drug search tool, and Doctor Directory."
      },
      {
        "term": "Copayment",
        "description": "A fixed dollar amount you pay for a <a href='/glossary#covered_services' target='_blank'>covered service<\/a>, usually when you receive the service. The amount can vary depending on the type of service. (For example, $25 to visit your doctor, $10 for <a href='/glossary#prescription_drugs' target='_blank'>prescription drugs<\/a>). Once you reach your <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a>, you no longer have copays for the rest of the <a href='/glossary#plan_year' target='_blank'>plan year<\/a>."
      },
      {
        "term": "Cosmetic Surgery",
        "description": "Another way of saying <a href='/glossary#plastic_surgery' target='_blank'>Plastic Surgery<\/a>."
      },
      {
        "term": "Cost-Sharing Reduction",
        "description": "A discount that lowers your costs for <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductibles<\/a>, <a href='/glossary#coinsurance' target='_blank'>coinsurance<\/a>, <a href='/glossary#copayment' target='_blank'>copayments<\/a>, and also lowers what you have to pay to reach your <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a>. To get these savings, you must apply for <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a>. Maine Cover ME will help you determine if you qualify as part of the application process. Then you can enroll. Most customers must enroll in a <a href='/glossary#silver_health_plan' target='_blank'>Silver Health Plan<\/a> to receive cost-sharing reductions. <a href='/glossary#native_american' target='_blank'>Native Americans<\/a> receive additional cost-sharing reductions regardless of a plan's <a href='/glossary#metal_level' target='_blank'>metal level<\/a>."
      },
      {
        "term": "Cover All ME",
        "description": "A <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> program available to Maine residents who don't meet eligibility requirements for Maine Cover ME (including private coverage or <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a>) or for the <a href='/glossary#dC_healthcare_alliance_program' target='_blank'>DC Healthcare Alliance Program<\/a>. Maine residents who are not incarcerated are eligible to enroll. Learn more about <a class='ext' href='https:\/\/dchealthlink.com\/node\/2478' target='_blank'>eligibility for Cover All DC<\/a>."
      },
      {
        "term": "Coverage",
        "description": "Another word for <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a>, <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a> or a <a href='/glossary#dental_plan' target='_blank'>dental plan<\/a>."
      },
      {
        "term": "Covered Services",
        "description": "The health care services you\u2019re entitled to receive based on the terms of your <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan. All plans available through Maine Cover ME cover <a href='/glossary#essential_health_benefits' target='_blank'>essential health benefits<\/a>. Other covered services or <a href='/glossary#excluded_services' target='_blank'>excluded services<\/a> will vary among plans. Each plan available through Maine Cover ME includes a <a href='/glossary#summary_of_benefits_and_coverage' target='_blank'>Summary of Benefits and Coverage<\/a>, but it's only a summary. You'll need to see your <a href='/glossary#plan_documents' target='_blank'>plan documents<\/a> for all benefits information. You can also call the insurance company directly if you have questions."
      },
      {
        "term": "ME Health Benefit Exchange Authority",
        "description": "An independent government authority established by the State of Maine to implement and operate Maine Cover ME - the State of Maine\u2019s health insurance marketplace. The Authority ensures access to quality, affordable health care for residents, small businesses and their employees in the State of Maine. For more information, visit the <a class='ext' href='http:\/\/hbx.dc.gov\/' target='_blank'>DCHBX website<\/a>."
      },
      {
        "term": "Maine Cover ME",
        "description": "the State of Maine's system for individuals, families, small businesses and their employees as well as members of Congress and their staff to access health and dental coverage through private health companies or <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a>."
      },
      {
        "term": "ME Healthcare Alliance Program",
        "description": "A managed care health plan that provides medical assistance to Maine residents who are not eligible for <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a>. The Alliance serves low-income Maine residents who have no other <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> and are not eligible for either Medicaid or <a href='https://www.medicare.gov/' target='_blank'>Medicare<\/a>. The program is sponsored and paid for by the State of Maine government. Learn more about <a class='ext' href='https:\/\/dchealthlink.com\/node\/2478' target='_blank'>eligibility for the DC Healthcare Alliance Program<\/a>."
      },
      {
        "term": "Maine Network",
        "description": "A designation that indicates the plan's <a href='/glossary#network' target='_blank'>network<\/a> of doctors, specialists, other providers, facilities and suppliers that plan members can access is limited to the DC metropolitan area."
      },
      {
        "term": "Maine Health Benefit Exchange Authority",
        "description": "The acronym for <a href='/glossary#dc_health_benefit_exchange_authority' target='_blank'>Maine Health Benefit Exchange Authority<\/a>."
      },
      {
        "term": "DDS",
        "description": "The acronym for the State of Maine\u2019s <a href='/glossary#department_of_disability_services' target='_blank'>Department of Disability Services<\/a>."
      },
      {
        "term": "Deductible",
        "description": "The amount you must pay during the <a href='/glossary#plan_year' target='_blank'>plan year<\/a> for <a href='/glossary#covered_services' target='_blank'>covered services<\/a> you use before your insurance company begins to contribute towards costs. For example, if your annual <a href='/glossary#in-network' target='_blank'>in-network<\/a> deductible is $1000, your health insurance company may not pay anything for covered services until you reach this amount. The deductible may not apply to all services. For example, most plans include certain <a href='/glossary#preventive_services' target='_blank'>preventive services<\/a> at no cost even before you meet your deductible. Some plans also have separate deductibles for specific benefits like <a href='/glossary#prescription_drugs' target='_blank'>prescription drugs<\/a>."
      },
      {
        "term": "Dental Plan",
        "description": "<a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>Health insurance<\/a> for routine, or preventive dental services such as teeth cleaning, fillings or x-rays. Dental coverage is considered an <a href='/glossary#essential_health_benefits' target='_blank'>essential health benefit<\/a> for children 18 years old or younger, and must be o\ufb00ered either as part of a health plan or as a stand-alone plan. Dental coverage is considered optional for adults and children under the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>, and you aren't required to buy it. You can purchase a dental plan through Maine Cover ME without purchasing private health coverage."
      },
      {
        "term": "Department of Disability Services",
        "description": "Provides Maine residents with information, oversight and coordination of services for people with disabilities and those who support them, such as service providers and employers. Learn more about <a class='ext' href='http:\/\/dds.dc.gov\/page\/dds-services' target='_blank'>DDS assistance programs<\/a>."
      },
      {
        "term": "Department of Health Care Finance",
        "description": "the State of Maine's state <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a> agency charged with improving health outcomes for Maine residents by providing access to comprehensive, cost-effective and quality healthcare services. DHCF also administers insurance programs for immigrant children, the State Child Health Insurance Program, and Medical Charities (a locally funded program). Learn more about <a class='ext' href='http:\/\/dhcf.dc.gov' target='_blank'>DHCF assistance programs<\/a>."
      },
      {
        "term": "Department of Human Services",
        "description": "This agency, in collaboration with the community, provides financial assistance and helps low-income individuals and families maximize their potential for economic security and self-sufficiency. Learn more about <a class='ext' href='https://www.maine.gov/dhhs/programs-services/human-services target='_blank'>DHS assistance programs<\/a>."
      },
      {
        "term": "Department of Insurance, Securities and Banking",
        "description": "This agency regulates financial-service businesses in the State of Maine by administering DC's insurance, securities and banking laws, rules and regulations. The agency's primary goal is to ensure residents of the State of Maine have access to a wide choice of insurance, securities and banking products and services, and that they are treated fairly by the companies and individuals that provide these services. For more information, <a class='ext' href='http:\/\/\/page\/about-disb' target='_blank'>visit the DISB website<\/a>."
      },
      {
        "term": "Dependent",
        "description": "Also referred to as <a href='/glossary#tax_dependent' target='_blank'>tax dependent<\/a>."
      },
      {
        "term": "DHCF",
        "description": "The acronym for the State of Maine\u2019s <a href='/glossary#department_of_health_care_finance' target='_blank'>Department of Health Care Finance<\/a>."
      },
      {
        "term": "DHS",
        "description": "The acronym for the State of Maine\u2019s <a href='https://www.maine.gov/dhhs/programs-services/human-services' target='_blank'>Department of Human Services<\/a>."
      },
      {
        "term": "Disability",
        "description": "A physical or mental impairment that restricts a person's ability to participate in everyday activities. For more information, refer to the <a class='ext' href='https:\/\/www.ada.gov\/pubs\/ada.htm' target='_blank'>legal definition of disability<\/a>."
      },
      {
        "term": "DISB",
        "description": "The acronym for the State of Maine\u2019s <a href='/glossary#department_of_insurance&#44;_securities_and_banking' target='_blank'>Department of Insurance&#44; Securities and Banking<\/a>."
      },
      {
        "term": "Doctor Directory",
        "description": "A feature of Maine Cover ME's <a href='/glossary#plan_match' target='_blank'>Plan Match<\/a> tool that allows you to filter plans and see the ones where your doctors are <a href='/glossary#in-network' target='_blank'>in-network<\/a>."
      },
      {
        "term": "Domestic Partnership",
        "description": "A legal classification that provides rights for two unmarried persons, 18 years old or older, living together, whether of the same gender or different genders, who are also the sole domestic partner of the other person. Domestic partnerships must be registered to gain access to rights provided by applicable laws. Learn more about <a class='ext' href='http:\/\/\/service\/domestic-partnership' target='_blank'>domestic partnerships in the State of Maine<\/a>."
      },
      {
        "term": "Drug Formulary",
        "description": "A more descriptive phrase for <a href='/glossary#formulary' target='_blank'>formulary<\/a>."
      },
      {
        "term": "Durable Medical Equipment",
        "description": "Equipment and other goods prescribed by a <a href='/glossary#service_provider' target='_blank'>service provider<\/a> to support patient care, often in home. Examples include but aren't limited to: wheelchairs, walkers, crutches, blood testing strips for diabetics or oxygen equipment."
      },
      {
        "term": "Early and Periodic Screening, Diagnostic, and Treatment Services",
        "description": "An umbrella term used to describe a comprehensive and preventive set of health care services for children under the age of 21 who are enrolled in <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a>."
      },
      {
        "term": "ECN",
        "description": "The acronym for <a href='/glossary#exemption_certificate_number' target='_blank'>Exemption Certificate Number<\/a>."
      },
      {
        "term": "EHB",
        "description": "The acronym for <a href='/glossary#essential_health_benefits' target='_blank'>Essential Health Benefits<\/a>."
      },
      {
        "term": "Eligible Expense",
        "description": "Also known as <a href='/glossary#allowed_amount' target='_blank'>Allowed Amount<\/a>."
      },
      {
        "term": "Employer Shared Responsibility Provision",
        "description": "The <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a> requires employers with 50 or more <a href='/glossary#full-time_equivalent_employee' target='_blank'>full-time equivalent employees<\/a> to offer <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> to their employees (and their <a href='/glossary#tax_dependent' target='_blank'>tax dependents<\/a>) that provides, <a href='/glossary#minimum_value' target='_blank'>minimum value<\/a> and is considered <a href='/glossary#affordable_coverage' target='_blank'>affordable coverage<\/a> or pay a penalty (called the employer shared responsibility payment). <a class='ext' href='https:\/\/www.irs.gov\/affordable-care-act\/employers\/questions-and-answers-on-employer-shared-responsibility-provisions-under-the-affordable-care-act' target='_blank'>Learn more about the provision<\/a>."
      },
      {
        "term": "Employer-Sponsored Health Insurance",
        "description": "Coverage offered to an employee by an employer (also called job-based coverage). At the employer's option, it may include family coverage. Typically, employers make a contribution towards the costs of your <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a>, and usually you'll have a choice of plans. You pay your share of the premium costs directly to your employer - typically through payroll deductions."
      },
      {
        "term": "EPO",
        "description": "The acronym for <a href='/glossary#exclusive_provider_organization' target='_blank'>Exclusive Provider Organization<\/a>, a type of <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan."
      },
      {
        "term": "EPSDT",
        "description": "The acronym for <a href='/glossary#early_and_periodic_screening&#44;_diagnostic&#44;_and_treatment_services' target='_blank'>Early and Periodic Screening, Diagnostic, and Treatment Services<\/a>."
      },
      {
        "term": "Essential Health Benefits",
        "description": "All <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plans available through Maine Cover ME are required by federal law to include what are called essential health benefits. These include: <a href='/glossary#ambulatory_patient_services' target='_blank'>ambulatory patient services<\/a>; emergency services; hospitalization; maternity and newborn care; mental health and substance use disorder services including behavioral health treatment; <a href='/glossary#prescription_drugs' target='_blank'>prescription drugs<\/a>; rehabilitation services and <a href='/glossary#habilitative_services' target='_blank'>habilitative services<\/a> and devices; laboratory services; <a href='/glossary#preventive_services' target='_blank'>preventive services<\/a> and chronic disease management; and pediatric services, including dental and vision care for children. This doesn\u2019t mean that all plans are the same. Some plans may o\ufb00er a higher level of service or additional services beyond the minimum required, or exclude other optional services that may be important to you. It\u2019s important to understand these di\ufb00erences when comparing and choosing a plan to meet your needs and budget."
      },
      {
        "term": "Exchange",
        "description": "Another word for a <a href='https://www.maine.gov/dhhs/programs-services/health-insurance_marketplace' target='_blank'>Health Insurance Marketplace<\/a>."
      },
      {
        "term": "Excluded Services",
        "description": "Health care services that your <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> doesn't pay for or cover such as <a href='/glossary#plastic_surgery' target='_blank'>plastic surgery<\/a> for non-medical reasons. Some services also require <a href='/glossary#pre-authorization' target='_blank'>pre-authorization<\/a> from your health insurance company or a referral from your <a href='/glossary#primary_care_physician' target='_blank'>primary care physician<\/a> in order to be considered <a href='/glossary#covered_services' target='_blank'>covered services<\/a>. Excluded services don't count towards your annual <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductible<\/a> or <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a>."
      },
      {
        "term": "Exclusive Provider Organization",
        "description": "A type of <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan where you can only use <a href='/glossary#in-network' target='_blank'>in-network<\/a> doctors, hospitals, specialists and other <a href='/glossary#service_provider' target='_blank'>service providers<\/a> except in an emergency."
      },
      // Rearranged so RegExp searches for larger terms first
      {
        "term": "Exemption Certificate Number",
        "description": "If you qualify for an <a href='/glossary#exemption' target='_blank'>exemption<\/a>, you'll receive an exemption certificate number (ECN), a unique identification number that you'll need when you file your federal tax return. This number is used to complete <a href='/glossary#irs_form_8965' target='_blank'>IRS Form 8965<\/a> for the year or time period when you didn't have <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a>. If more than one person in your household qualifies for an exemption, each person will be assigned their own ECN."
      },
      {
        "term": "Exemption",
        "description": "If you don't want to or forgot to buy <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a>, or don't believe you can afford it, you must get a formal exemption or you may have to pay a penalty when you file your taxes (the <a href='/glossary#individual_shared_responsibility_payment' target='_blank'>Individual Shared Responsibility Payment<\/a>). Some exemptions can be claimed when you file your tax return, but others must be granted in advance by the <a href='/glossary#us_department_of_health_and_human_services' target='_blank'>U.S. Department of Health and Human Services<\/a>. If you're not required to file a federal tax return because your gross income is below the filing threshold, you automatically have an exemption and don't need to do anything. <a class='ext' href='https:\/\/www.irs.gov\/affordable-care-act\/individuals-and-families\/aca-individual-shared-responsibility-provision-exemptions' target='_blank'>See exemptions and who grants them<\/a> to find out whether you need to <a class='ext' href='https:\/\/www.healthcare.gov\/health-coverage-exemptions\/forms-how-to-apply\/' target='_blank'>apply for an exemption<\/a> in advance. Exemptions are claimed on <a href='/glossary#irs_form_8965' target='_blank'>IRS Form 8965<\/a> when you file your taxes."
      },
      {
        "term": "Family",
        "description": "You, your spouse, and other <a href='/glossary#tax_dependent' target='_blank'>tax dependents<\/a> as defined by the IRS. Eligibility for <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a>, help paying for <a href='/glossary#private_health_insurance' target='_blank'>private health insurance<\/a> and other <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a> programs is based on the income of all <a href='/glossary#household' target='_blank'>household<\/a> members even if all members don't need coverage."
      },
      {
        "term": "Federal Poverty Level",
        "description": "A measure of income used to determine eligibility for certain <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a> programs. The guidelines are issued each year by the <a href='/glossary#us_department_of_health_and_human_services' target='_blank'>US Department of Health and Human Services<\/a>. Learn more about <a class='ext' href='https:\/\/aspe.hhs.gov\/poverty-guidelines' target='_blank'>this year's FPL guidelines<\/a>."
      },
      {
        "term": "Federally Qualified Health Center",
        "description": "Nonprofit health centers or clinics that receive federal funding to serve medically underserved areas and populations. The centers provide low cost to no cost <a href='/glossary#primary_care' target='_blank'>primary care<\/a> services on a sliding scale fee, based on your ability to pay. There are several <a class='ext' href='http:\/\/\/sites\/default\/files\/dc\/sites\/doh\/publication\/attachments\/DC_Fqhc_Site_List.pdf' target='_blank'>federally qualified health centers in the State of Maine<\/a>. "
      },
      {
        "term": "Federally Recognized Tribe",
        "description": "An <a href='/glossary#american_indian' target='_blank'>American Indian<\/a> or <a href='/glossary#alaskan_native' target='_blank'>Alaska Native<\/a> tribal entity that is recognized as having a government-to-government relationship with the United States. Members are eligible for enhanced savings, benefits and protections through Maine Cover ME, and should apply for <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a> prior to choosing a health plan to determine eligibility and the savings, benefits and protections available."
      },
      {
        "term": "Financial Assistance",
        "description": "An umbrella terms used by Maine Cover ME to describe <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a>, and federal programs that help you pay for <a href='/glossary#private_health_insurance' target='_blank'>private health insurance<\/a> like <a href='/glossary#advance_premium_tax_credit' target='_blank'>advance premium tax credits<\/a> and <a href='/glossary#cost-sharing_reduction' target='_blank'>cost-sharing reductions<\/a>. In the State of Maine, there are many other financial assistance programs for health care and other services. You can learn more about these programs from the State of Maine's <a href='/glossary#department_of_health_care_finance' target='_blank'>Department of Health Care Finance<\/a> and the <a href='https://www.maine.gov/dhhs/programs-services/human-services' target='_blank'>Department of Human Services<\/a>."
      },
      {
        "term": "Food Stamps",
        "description": "The informal name for the <a href='/glossary#supplemental_nutrition_assistance_program' target='_blank'>Supplemental Nutrition Assistance Program<\/a>."
      },
      {
        "term": "Formulary",
        "description": "A list of <a href='/glossary#prescription_drugs' target='_blank'>prescription drugs<\/a> that are covered by your <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan. Formularies often divide drugs into 'tiers' or categories, which determine your share of the costs. Prescription drugs are considered an <a href='/glossary#essential_health_benefits' target='_blank'>essential health benefit<\/a> under the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>. "
      },
      {
        "term": "FPL",
        "description": "The acronym for the <a href='/glossary#federal_poverty_level' target='_blank'>Federal Poverty Level<\/a>."
      },
      {
        "term": "FQHC",
        "description": "The acronym for <a href='/glossary#federally_qualified_health_center' target='_blank'>Federally Qualified Health Center<\/a>."
      },
      {
        "term": "Full-time Equivalent Employee",
        "description": "Small businesses must have at least 1 full-time equivalent employee to purchase <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> through Maine Cover ME\u2019s Small Business Marketplace. All employees (not including owners, partners or family members) who work on average, at least 30 hours a week are considered full-time employees. Part-time employees can count towards calculating the number of full-time equivalent employees. For example, 2 part-time employees who each work 15 hours a week - half the hours of a full-time employee - equal 1 full-time equivalent employee. (2x.50=1)"
      },
      {
        "term": "Generic Drugs",
        "description": "A <a href='/glossary#prescription_drugs' target='_blank'>prescription drug<\/a> that has the same active-ingredient formula as a <a href='/glossary#brand_name_drug' target='_blank'>brand-name drug<\/a>. Generic drugs usually cost less than brand name drugs. The Food and Drug Administration (FDA) rates these drugs to be as safe and effective as brand name drugs."
      },
      {
        "term": "Gold Health Plan",
        "description": "Gold Health Plans pay 80 percent of <a href='/glossary#in-network' target='_blank'>in-network<\/a> expenses for an average population of consumers. The <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> are typically higher but the <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductible<\/a> and <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a> of what you'll pay before the plan starts paying are lower. <a href='/glossary#metal_level' target='_blank'>Metal levels<\/a> only focus on what the plan is expected to pay, and do NOT reflect the quality of health care or <a href='/glossary#service_provider' target='_blank'>service providers<\/a> available through the <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan. Once you meet your in-network out-of-pocket limit for the <a href='/glossary#plan_year' target='_blank'>plan year<\/a>, plans pay 100 percent of the <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a> for <a href='/glossary#covered_services' target='_blank'>covered services<\/a>. "
      },
      {
        "term": "Grandfathered Plan",
        "description": "A health plan that's exempt from some provisions of the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>. Grandfathered plans count as having <a href='/glossary#minimum_essential_coverage' target='_blank'>minimum essential coverage<\/a>. Health insurance companies are required to disclose if a plan is grandfathered in <a href='/glossary#plan_documents' target='_blank'>plan documents<\/a>."
      },
      {
        "term": "Group Health Plan",
        "description": "An umbrella term generally used to describe a health plan offered by either an employer or an employee organization (such as a union) that provides medical coverage to <a href='/glossary#plan_participants' target='_blank'>plan participants<\/a>. "
      },
      {
        "term": "Guaranteed Issue",
        "description": "A health plan that must let you enroll regardless of <a href='/glossary#age' target='_blank'>age<\/a>, income, <a href='/glossary#health_status' target='_blank'>health status<\/a> or potential use of <a href='/glossary#covered_services' target='_blank'>covered services<\/a> as long as you pay your monthly <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a>. "
      },
      {
        "term": "Guaranteed Renewal",
        "description": "A health plan that must let you renew the policy (if it's still available) as long as you pay your monthly <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a>. "
      },
      {
        "term": "Guardianship",
        "description": "A person with the legal authority and obligation to make financial as well as personal care decisions on behalf of another person. In the <a class='ext' href='http:\/\/odr.dc.gov\/book\/path-community-living-resource-guide\/legal-guardianship' target='_blank'>Maine, legal guardianship<\/a> for minors and \u201cincapacitated adults\u201d is implemented through the Superior Court of DC Probate Division Court. "
      },
      {
        "term": "Habilitative Services",
        "description": "Health care services such as occupational, physical, speech and psychiatric therapy that focus on helping develop new skills that improve daily living. Examples include therapy for a child who isn't walking or talking at the expected age.  "
      },
      {
        "term": "Hardship Exemption",
        "description": "One kind of exemption from the health care law\u2019s requirement that most Americans have <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> or pay a penalty. See the definition of <a href='/glossary#exemption' target='_blank'>exemption<\/a> for more information."
      },
      {
        "term": "HCBS",
        "description": "The acronym for <a href='/glossary#home_and_community-based_services' target='_blank'>Home and Community-Based Services<\/a>."
      },
      {
        "term": "HDHP",
        "description": "The acronym for a <a href='/glossary#high_deductible_health_plan' target='_blank'>High Deductible Health Plan<\/a>."
      },
      {
        "term": "Health Care and Education Reconciliation Act",
        "description": "One of the health care laws commonly referred to as the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>."
      },
      // Rearranged so RegExp searches for larger terms first
      {
        "term": "Health Insurance Marketplace Statement",
        "description": "Another name for <a href='/glossary#irs_form_1095-a' target='_blank'>IRS Form 1095-A<\/a>."
      },
      {
        "term": "Health Insurance Marketplace",
        "description": "A state-based or federally-facilitated exchange where individuals, families, small businesses and their employees can get quality, affordable <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a>. the State of Maine's health insurance marketplace is available at <a class='ext' href='http:\/\/www.dchealthlink.com\/' target='_blank'>dchealthlink.com<\/a>. "
      },
      {
        "term": "Health Insurance",
        "description": "A contract (also called a plan or policy) that requires the health insurance company that issues the plan to pay some of your health care costs in exchange for the <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premium<\/a> payment you make. If you don't make your premium payments on time, your health insurance company can cancel your plan. "
      },
      {
        "term": "Health Insurance Plan",
        "description": "Another name for <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a>."
      },
      {
        "term": "Health Insurance Portability and Accountability Act",
        "description": "A federal law that sets rules about who can see, use or share your health information and provides other protections to consumers. Commonly referred to as HIPAA, the law gives you rights over your health information, and requires doctors, pharmacists, other health care providers, and your health plan to explain your rights. The law has specific privacy and security requirements to safeguard your electronic health information, and to notify you if there's ever a breach. "
      },
      {
        "term": "Health Maintenance Organization",
        "description": "An HMO (Health Maintenance Organization) is a type of health plan that usually only covers care from <a href='/glossary#in-network' target='_blank'>in-network<\/a> <a href='/glossary#service_provider' target='_blank'>service providers<\/a>. It generally won't cover <a href='/glossary#out-of-network' target='_blank'>out-of-network<\/a> care except in an emergency, and may require you to live or work in its <a href='/glossary#service_area' target='_blank'>service area<\/a> to be eligible for coverage. You may be required to choose a <a href='/glossary#primary_care_physician' target='_blank'>primary care physician<\/a>."
      },
      {
        "term": "Health Reimbursement Account",
        "description": "An optional, <a href='/glossary#employer-sponsored_health_insurance' target='_blank'>employer-sponsored<\/a> benefit funded by the employer that reimburses <a href='/glossary#plan_participants' target='_blank'>plan participants<\/a> for <a href='/glossary#qualified_medical_expenses' target='_blank'>qualified medical expenses<\/a> up to a fixed amount. The reimbursements are tax free, and any unused funds can be rolled over for use in future years. These types of accounts are not <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a>."
      },
      {
        "term": "Health Savings Account",
        "description": "If you have a <a href='/glossary#high_deductible_health_plan' target='_blank'>High Deductible Health Plan<\/a>, you may be eligible for a Health Savings Account (HSA) where you (and if applicable, your employer) can deposit pre-tax dollars to pay for <a href='/glossary#qualified_medical_expenses' target='_blank'>qualified medical expenses<\/a> like your <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductible<\/a>, <a href='/glossary#copayment' target='_blank'>copayments<\/a> and <a href='/glossary#coinsurance' target='_blank'>coinsurance<\/a>. There's an annual limit on contributions established by the IRS, but any funds deposited can be used in future years. If you have an HSA through your employer, the funds belong to you and can rollover into another qualifying account if you ever leave. "
      },
      {
        "term": "Health Status",
        "description": "Medical conditions and health history. Under the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>, your health status has no impact on your ability to get <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> or the cost of it. In the State of Maine, smoking also doesn't factor into the cost of your health insurance, and <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> are based solely on your age."
      },
      {
        "term": "Healthcare.gov",
        "description": "The website for the federally-facilitated <a href='https://www.maine.gov/dhhs/programs-services/health-insurance_marketplace' target='_blank'>health insurance marketplace<\/a> used by many states to help meet the provisions of the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>. the State of Maine operates its own health insurance marketplace accessible through <a class='ext' href='http:\/\/www.dchealthlink.com\/' target='_blank'>Maine Cover ME<\/a>; however, Maine residents who need an <a href='/glossary#exemption' target='_blank'>exemption<\/a> from having <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> apply for it through <a class='ext' href='https:\/\/www.healthcare.gov\/' target='_blank'>healthcare.gov<\/a>"
      },
      {
        "term": "HHS",
        "description": "The acronym for the <a href='/glossary#us_department_of_health_and_human_services' target='_blank'>US Department of Health and Human Services<\/a>."
      },
      {
        "term": "High Deductible Health Plan",
        "description": "A feature of some health plans. HDHPs have a higher annual <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductible<\/a> and typically lower monthly <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a>. You pay more for health care up front before your insurance company starts to pay. With an HDHP, you're eligible to open a tax deductible <a href='/glossary#health_savings_account' target='_blank'>Health Savings Account<\/a> or <a href='/glossary#health_reimbursement_account' target='_blank'>Health Reimbursement Account<\/a> to pay for <a href='/glossary#qualified_medical_expenses' target='_blank'>qualified medical expenses<\/a> like your annual deductible, <a href='/glossary#copayment' target='_blank'>copayments<\/a> or <a href='/glossary#coinsurance' target='_blank'>coinsurance<\/a>. The IRS defines the limits for plans that qualify as HDHPs and the deductible and <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a> may be adjusted annually for inflation. "
      },
      {
        "term": "HIPAA",
        "description": "The acronym for a federal law known as the <a href='https://www.maine.gov/dhhs/programs-services/health-insurance_portability_and_accountability_act' target='_blank'>Health Insurance Portability and Accountability Act<\/a>."
      },
      {
        "term": "HMO",
        "description": "The acronym for <a href='/glossary#health_maintenance_organization' target='_blank'>Health Maintenance Organization<\/a> \u2013 a type of <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan."
      },
      {
        "term": "Home and Community-Based Services",
        "description": "An alternative to institutional residential services that offers a wide range of daily living, respite, vocational, employment, retirement, social, clinical, therapy and adaptive services and supports in the home and community in a variety of settings. "
      },
      {
        "term": "Home Health Care",
        "description": "Health services you receive at home, such as but not limited to: skilled nursing, physical therapy, occupational therapy, or medical supplies and equipment. These services are typically prescribed by your doctor and provided by a home health agency approved by your <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> company."
      },
      {
        "term": "Hospice Services",
        "description": "Medical care, comfort and support services for patients in the late stages of a terminal illness. Care can typically be provided in the patient's home or in a medical facility. "
      },
      {
        "term": "Hospital Readmissions",
        "description": "When you're released from the hospital, but have to go back for the same or a related medical condition. Readmission rates are considered a measure of the quality of care patients receive. One goal of the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a> is to lower excessive readmission rates. "
      },
      {
        "term": "Hospitalization",
        "description": "Another word for <a href='/glossary#inpatient_care' target='_blank'>Inpatient Care<\/a>."
      },
      {
        "term": "Household",
        "description": "You, your spouse, and other <a href='/glossary#tax_dependent' target='_blank'>tax dependents<\/a> as defined by the IRS. Eligibility for <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a>, help paying for <a href='/glossary#private_health_insurance' target='_blank'>private health insurance<\/a> and other <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a> programs is based on the income of all household members even if all members don't need <a href='/glossary#coverage' target='_blank'>coverage<\/a>. "
      },
      {
        "term": "HRA",
        "description": "The acronym for <a href='/glossary#health_reimbursement_account' target='_blank'>Health Reimbursement Account<\/a>."
      },
      {
        "term": "HSA",
        "description": "The acronym for <a href='/glossary#health_savings_account' target='_blank'>Health Savings Account<\/a>."
      },
      {
        "term": "I\/T\/U",
        "description": "An acronym that encompasses <a href='https://www.ihs.gov/findhealthcare/' target='_blank'>Indian Health Service<\/a> Providers, Tribal Health Providers, and Urban Indian Health Providers."
      },
      {
        "term": "ICP",
        "description": "The acronym for the State of Maine's <a href='/glossary#immigrant_children&#39;s_program' target='_blank'>Immigrant Children's Program<\/a>."
      },
      {
        "term": "IDA",
        "description": "The acronym for the State of Maine\u2019s <a href='/glossary#interim_disability_assistance_program' target='_blank'>Interim Disability Assistance Program<\/a>."
      },
      {
        "term": "Immigrant Children's Program",
        "description": "A health coverage program available to children under the age of 21 who aren't eligible for <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a> due to citizenship or immigration status. Learn more about <a class='ext' href='http:\/\/dhcf.dc.gov\/service\/immigrant-childrens-program' target='_blank'>the State of Maine's Immigrant Children's Program<\/a>."
      },
      {
        "term": "Indian Health Service",
        "description": "An agency within the <a href='/glossary#us_department_of_health_and_human_services' target='_blank'>US Department of Health and Human Services<\/a> that administers the federal health program for <a href='/glossary#american_indian' target='_blank'>American Indians<\/a> and <a href='/glossary#alaskan_native' target='_blank'>Alaska Natives<\/a>."
      },
      {
        "term": "Individual & Family Health Insurance",
        "description": "<a href='/glossary#private_health_insurance' target='_blank'>Private health insurance<\/a> available through Maine Cover ME. <a href='/glossary#advance_premium_tax_credit' target='_blank'>Advance premium tax credits<\/a> and <a href='/glossary#cost-sharing_reduction' target='_blank'>cost-sharing reductions<\/a> can be used to help pay for private coverage for eligible customers."
      },
      {
        "term": "Individual Shared Responsibility Payment",
        "description": "If you don't have <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> that provides <a href='/glossary#minimum_essential_coverage' target='_blank'>minimum essential coverage<\/a>, or you don't qualify for an <a href='/glossary#exemption' target='_blank'>exemption<\/a>, you may have to pay a penalty when you file your federal tax return. This is called the individual shared responsibility payment. The penalty will never be higher than the national average <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premium<\/a> for a <a href='/glossary#bronze_health_plan' target='_blank'>bronze health plan<\/a> (the least expensive type of comprehensive plan). <a class='ext' href='https:\/\/dchealthlink.com\/go-without-insurance' target='_blank'>Learn more about the penalty<\/a>. "
      },
      {
        "term": "Individual Shared Responsibility Provision",
        "description": "The <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a> requires most people to either have <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> that provides <a href='/glossary#minimum_essential_coverage' target='_blank'>minimum essential coverage<\/a>, get an <a href='/glossary#exemption' target='_blank'>exemption<\/a>, or pay a penalty which is called the <a href='/glossary#individual_shared_responsibility_payment' target='_blank'>individual shared responsibility payment<\/a>."
      },
      {
        "term": "In-Network",
        "description": "The <a href='/glossary#service_provider' target='_blank'>service providers<\/a> and suppliers your <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> company has contracted with to provide health care services. Some health insurance plans will only let you use in-network (sometimes called \u201cpreferred\u201d) service providers, and only cover <a href='/glossary#out-of-network' target='_blank'>out-of-network<\/a> providers on a limited basis. It also costs less to use in-network service providers. If you have a doctor or other service provider that you want to keep using, make sure they are in-network for the health insurance plan you choose."
      },
      {
        "term": "Inpatient Care",
        "description": "Medical care received after formally being admitted to a hospital or medical facility on a doctor's order. Inpatient care includes services like room, board and nursing care and typically requires an overnight stay. Inpatient care is usually more expensive than <a href='/glossary#outpatient_care' target='_blank'>outpatient care<\/a>, and may require <a href='/glossary#pre-authorization' target='_blank'>pre-authorization<\/a> from your insurance company unless it's an emergency."
      },
      {
        "term": "Interim Disability Assistance Program",
        "description": "Provides temporary financial assistance to those who are unable to work due to a disability and have a high probability of receiving federal <a href='/glossary#supplemental_security_income' target='_blank'>Supplemental Security Income (SSI)<\/a>.  IDA payments are issued until SSI eligibility is approved or denied. <a class='ext' href='http:\/\/\/service\/interim-disability-assistance' target='_blank'>Learn more about IDA<\/a>."
      },
      {
        "term": "IRS Form 1095-A",
        "description": "A federal tax form, also called the Health Insurance Marketplace Statement, that shows how long you had individual (or family) <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> through a health insurance marketplace during the tax year. If you received an <a href='/glossary#advance_premium_tax_credit' target='_blank'>advance premium tax credit<\/a> to help pay for your insurance, Form 1095-A will also show how much premium assistance you received each month. If you received <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premium<\/a> assistance, you\u2019ll need the information on Form 1095-A to complete the Premium Tax Credit <a href='https://www.mainecahc.org/wp-content/uploads/2016/03/Taxes-and-the-Marketplace.pdf' target='_blank'>IRS Form 8962<\/a>. Maine Cover ME will mail your Form 1095-A at the end of January. You can also <a class='ext' href='https://www.irs.gov/instructions/i109495b' target='_blank'>Download Form 1095-A<\/a> in early February."
      },
      {
        "term": "IRS Form 1095-B",
        "description": "A federal tax form sent to the IRS and to taxpayers who either had <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a>, <a href='/glossary#chip' target='_blank'>CHIP<\/a> or <a href='/glossary#employer-sponsored_health_insurance' target='_blank'>employer-sponsored coverage<\/a>. Medicaid and CHIP beneficiaries in the State of Maine receive the form from Maine Cover ME by the end of January. Employees receive the form directly from their insurance company. The form shows how long you had <a href='/glossary#minimum_essential_coverage' target='_blank'>minimum essential coverage<\/a> during the tax year."
      },
      {
        "term": "IRS Form 8962",
        "description": "If you were eligible for and want to claim a premium tax credit, or received an <a href='/glossary#advance_premium_tax_credit' target='_blank'>advance premium tax credit<\/a> to lower your monthly <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premium<\/a>, you must file <a class='ext' href='https:\/\/www.irs.gov\/uac\/about-form-8962' target='_blank'>Form 8962<\/a> with your federal tax return. The form is used to reconcile your tax credit, comparing the amount you received in advance, and the amount for which you\u2019re actually eligible. This may result in an additional credit, or you may have to repay some or all of the tax credit you received. <a href='/glossary#irs_form_1095-a' target='_blank'>https://www.irs.gov/instructions/i109495b<\/a> provides the information needed to complete this form. "
      },
      {
        "term": "IRS Form 8965",
        "description": "A federal tax form that must be filed with your tax return if you received a health coverage <a href='/glossary#exemption' target='_blank'>exemption<\/a> or if you're claiming a coverage exemption on your return. <a class='ext' href='https:\/\/www.irs.gov\/uac\/about-form-8965' target='_blank'>Form 8965<\/a> is also used to calculate the penalty for not having coverage (known as the <a href='/glossary#individual_shared_responsibility_payment' target='_blank'>Individual Shared Responsibility Payment<\/a>) that you must pay if you don't qualify for an exemption."
      },
      {
        "term": "Job-based Health Plan",
        "description": "Another name for <a href='/glossary#employer-sponsored_health_insurance' target='_blank'>Employer-Sponsored Health Insurance<\/a>."
      },
      {
        "term": "Katie Beckett Program",
        "description": "An eligibility pathway for the State of Maine\u2019s <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a> Program for certain children who have long-term disabilities or complex medical needs and live at home. Also known as the Tax Equity Fiscal Responsibility Act (TEFRA). Learn more about <a class='ext' href='http:\/\/dhcf.dc.gov\/service\/tax-equity-and-fiscal-responsibility-act-tefrakatie-beckett' target='_blank'>eligibility for the Katie Beckett Program<\/a>."
      },
      {
        "term": "Large Group Health Plan",
        "description": "A health benefits program offered by employers with 51 or more employees. In the State of Maine, large group health plans are purchased directly from insurance companies. "
      },
      {
        "term": "Life Changes",
        "description": "Also called a <a href='/glossary#qualifying_life_event' target='_blank'>Qualifying Life Event<\/a>, certain life changes may make you eligible to enroll in <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> coverage outside of the annual <a href='/glossary#open_enrollment' target='_blank'>open enrollment<\/a> period in what's called a <a href='/glossary#special_enrollment_period' target='_blank'>special enrollment period<\/a>, or make changes to your plan during the year."
      },
      {
        "term": "Life Event",
        "description": "Also called a <a href='/glossary#qualifying_life_event' target='_blank'>Qualifying Life Event<\/a>, certain life events may make you eligible to enroll in <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> coverage outside of the annual <a href='/glossary#open_enrollment' target='_blank'>open enrollment<\/a> period in what's called a <a href='/glossary#special_enrollment_period' target='_blank'>special enrollment period<\/a>, or make changes to your plan during the year."
      },
      {
        "term": "Lifetime Limit",
        "description": "The most your insurance company will pay for benefits in your lifetime, how many times you can receive a service in your lifetime, or how much your insurance company will spend on a particular service in your lifetime. Under the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>, most health plans (including all plans available through <a href='https://www.maine.gov/dhhs/programs-services/health-insurance_marketplace' target='_blank'>health insurance marketplaces<\/a>) don\u2019t have lifetime limits."
      },
      {
        "term": "Limited Cost-Sharing Plan",
        "description": "Members of <a href='/glossary#federally_recognized_tribe' target='_blank'>federally recognized Tribes<\/a> and <a href='/glossary#alaskan_native' target='_blank'>Alaska Native<\/a> Claims Settlement Act (ANCSA) Corporation shareholders are eligible for this type of plan regardless of income or eligibility for <a href='/glossary#advance_premium_tax_credit' target='_blank'>advance premium tax credits<\/a>. With this plan, there aren\u2019t any <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductibles<\/a>, <a href='/glossary#copayment' target='_blank'>copayments<\/a>, or <a href='/glossary#coinsurance' target='_blank'>coinsurance<\/a> when getting care through the <a href='https://www.ihs.gov/findhealthcare/' target='_blank'>Indian Health Service<\/a>, Tribal Health Providers, or Urban Indian Health Providers. <a href='/glossary#plan_participants' target='_blank'>Plan participants<\/a> must have a referral from an <a href='/glossary#i\/t\/u' target='_blank'>I\/T\/U<\/a> provider to receive <a href='/glossary#covered_services' target='_blank'>covered services<\/a> from an <a href='/glossary#in-network' target='_blank'>in-network<\/a> <a href='/glossary#service_provider' target='_blank'>service provider<\/a> at no cost. "
      },
      {
        "term": "Limited Enrollment Period",
        "description": "Small businesses that can't meet minimum participation and\/or matching contribution requirements to create a health benefits program that begins on the month of their choice may still be eligible to do so during an annual limited enrollment period. This typically takes place towards the end of the year for coverage that's effective January 1."
      },
      {
        "term": "Long-Term Care",
        "description": "Medical and non-medical services provided to people who are unable to perform basic activities most people do every day without assistance, such as walking, dressing or bathing.  Long-term care insurance is typically purchased as a stand-alone plan. <a href='https://www.medicare.gov/' target='_blank'>Medicare<\/a> and most <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plans don\u2019t pay for long-term care. the State of Maine does offer some <a class='ext' href='' target='_blank'>long-term care programs for eligible Maine residents<\/a>. "
      },
      {
        "term": "MAGI",
        "description": "The acronym for <a href='/glossary#modified_adjusted_gross_income' target='_blank'>Modified Adjusted Gross Income<\/a>."
      },
      {
        "term": "MEC",
        "description": "The acronym for <a href='/glossary#minimum_essential_coverage' target='_blank'>Minimum Essential Coverage<\/a>."
      },
      {
        "term": "Medicaid",
        "description": "Medicaid is a joint federal-state health program that provides health care coverage to low-income and disabled adults, children and families. To be eligible for Maine Medicaid, you must be a Maine resident and must meet non-financial and financial eligibility requirements. Medicaid covers many services, including doctor visits, hospital care, <a href='https://www.healthcare.gov/using-marketplace-coverage/prescription-medications/' target='_blank'>prescription drugs<\/a>, mental health services, transportation and many other services at little or no cost to the individual. Currently, 1 out of every 3 Maine residents receives quality health care coverage through the Medicaid program. <a class='ext' href='https://www.maine.gov/pfr/insurance/glossary.html#mainecare' target='_blank'>Learn more about Maine Medicaid<\/a>. "
      },
      {
        "term": "Medical Coverage",
        "description": "<a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>Health Insurance<\/a>"
      },
      {
        "term": "Medical Loss Ratio",
        "description": "Federal law requires <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> companies to use at least 80 percent of <a href='https://www.maine.gov/pfr/insurance/glossary.html#premium' target='_blank'>premium<\/a> dollars for health care expenses (85 percent for large group health plans). If an insurance company spends less, they must pay a rebate to employers or consumers. Rebates are based on the insurance company's health care spending across all health plans in the state. Employers are required to share the rebates with their employees based on the percentage of premiums paid. "
      },
      {
        "term": "Medically Necessary",
        "description": "Health care services or supplies that meet accepted standards of medicine that are needed to diagnose or treat an illness, injury, condition, disease, or its symptoms."
      },
      {
        "term": "Medicare",
        "description": "A federal <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> program for people who are 65 or older, certain younger people with disabilities, and people with end-stage renal disease (permanent kidney failure requiring dialysis or a transplant, sometimes called ESRD). The program helps with the cost of health care, but it doesn't cover all medical expenses or the cost of most <a href='/glossary#long-term_care' target='_blank'>long-term care<\/a>.  The program is administered through the <a href='/glossary#social_security_administration' target='_blank'>Social Security Administration<\/a>, not through Maine Cover ME. Learn more about <a class='ext' href='https:\/\/www.ssa.gov\/medicare\/' target='_blank'>when and how to apply for Medicare<\/a>. "
      },
      {
        "term": "Metal Level",
        "description": "Plans are assigned metal levels to indicate how generous they are in paying expenses. Metal levels only focus on what the plan is expected to pay, and do NOT reflect the quality of health care or <a href='/glossary#service_provider' target='_blank'>service providers<\/a> available through the <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan. <a href='/glossary#bronze_health_plan' target='_blank'>Bronze Health Plans<\/a> pay 60 percent of medical expenses for the average population of consumers, <a href='/glossary#silver_health_plan' target='_blank'>Silver Health Plans<\/a> 70 percent, <a href='/glossary#gold_health_plan' target='_blank'>Gold Health Plans<\/a> 80 percent, and <a href='/glossary#platinum_health_plan' target='_blank'>Platinum Health Plans<\/a> 90 percent. Bronze and Silver plans generally have lower <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a>, but you pay more when you get <a href='/glossary#covered_services' target='_blank'>covered services<\/a>. Gold and Platinum plans generally have higher premiums, but you pay less when you get covered services. "
      },
      {
        "term": "Mini Cobra",
        "description": "Also known as <a href='/glossary#state_continuation_coverage' target='_blank'>State Continuation Coverage<\/a>."
      },
      {
        "term": "Minimum Essential Coverage",
        "description": "Health coverage that meets the requirement of the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a> that most Americans have health insurance and certain other standards. All private health plans available through Maine Cover ME meet or exceed this standard. <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid (Maine Care)<\/a> and <a href='https://www.medicare.gov/' target='_blank'>Medicare<\/a> also qualify. If you get your medical coverage outside of Maine Cover ME or through another government program, <a class='ext' href='https:\/\/www.irs.gov\/affordable-care-act\/individuals-and-families\/aca-individual-shared-responsibility-provision-minimum-essential-coverage' target='_blank'>find out what kind of health coverage qualifies as minimum essential coverage<\/a>."
      },
      {
        "term": "Minimum Value",
        "description": "A standard applied to <a href='/glossary#employer-sponsored_health_insurance' target='_blank'>employer-sponsored health insurance<\/a>. A plan meets the standard if it pays at least 60 percent of the total cost of medical services for a standard population of consumers and o\ufb00ers substantial coverage of hospital and doctor services. If your employer\u2019s plan meets this standard and is considered a\ufb00ordable, you won\u2019t be eligible for an <a href='/glossary#advance_premium_tax_credit' target='_blank'>advance premium tax credit<\/a> if you buy a private plan through Maine Cover ME's <a href='/glossary#individual_&_family_health_insurance' target='_blank'>Individual & Family marketplace<\/a> instead."
      },
      {
        "term": "Modified Adjusted Gross Income",
        "description": "The way your income is calculated to see whether or not you qualify for <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a> or an <a href='/glossary#advance_premium_tax_credit' target='_blank'>advance premium tax credit<\/a>. MAGI is your <a href='/glossary#household' target='_blank'>household's<\/a> Adjusted Gross Income (as calculated when you file your taxes) plus any non-taxable <a href='/glossary#social_security' target='_blank'>Social Security<\/a> benefits, tax-exempt interest, and foreign income."
      },
      {
        "term": "Nationwide Network",
        "description": "A designation that indicates the plan's <a href='/glossary#network' target='_blank'>network<\/a> of doctors, specialists, other <a href='/glossary#service_provider' target='_blank'>service providers<\/a>, facilities and suppliers that plan members can access is national."
      },
      {
        "term": "Native American",
        "description": "If you're a Native American, member of a <a href='/glossary#federally_recognized_tribe' target='_blank'>federally recognized Tribe<\/a>, <a href='/glossary#alaskan_native' target='_blank'>Alaska Native<\/a> Claims Settlement Act (ANCSA) corporation shareholder or otherwise eligible for services from the <a href='https://www.ihs.gov/findhealthcare/' target='_blank'>Indian Health Service<\/a>, Tribal Program, or Urban Indian Health Program, enhanced savings, benefits and protections are likely available to you through Maine Cover ME. You should apply for <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a> prior to choosing a health plan to determine the savings, benefits and protections available to you. "
      },
      {
        "term": "Navigator",
        "description": "The Maine Cover ME Navigator Program is a partnership with community organizations that have experience successfully reaching, educating, and enrolling the State of Maine\u2019s diverse uninsured and hard-to-reach populations into <a href='/glossary#qualified_health_plan' target='_blank'>Qualified Health Plans<\/a> (QHPs) and insurance affordability programs. The program also provides effective post-enrollment and renewal support services to consumers, as appropriate. "
      },
      {
        "term": "Negotiated Rate",
        "description": "Also referred to as an <a href='/glossary#allowed_amount' target='_blank'>Allowed Amount<\/a>."
      },
      {
        "term": "Network",
        "description": "Doctors, specialists, other <a href='/glossary#service_provider' target='_blank'>service providers<\/a>, facilities and suppliers that a <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> company contracts with to provide health care services to plan members."
      },
      {
        "term": "Non-Preferred Provider",
        "description": "Also referred to as an <a href='/glossary#out-of-network' target='_blank'>out-of-network<\/a> provider."
      },
      {
        "term": "Notice",
        "description": "Once you sign up for <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a>, from time to time, you may receive important information about your health insurance in the mail or an alert by email that a new notice is available when you login to your Maine Cover ME account. Notices are time sensitive and may impact your health insurance, so it\u2019s important that you read them and take action, if required. "
      },
      {
        "term": "Obamacare",
        "description": "The healthcare laws officially known as the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>."
      },
      {
        "term": "Open Enrollment",
        "description": "A limited period of time every year when people can enroll in a <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan for the next plan year. For individuals and families, the annual open enrollment season is every fall and usually lasts 3 months. If your employer offers health insurance, the open enrollment time will be shorter and at a different time, so you should check with your employer on when you can enroll. You can apply for and enroll in <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a> any time of the year."
      },
      {
        "term": "Out-of-Network",
        "description": "Some plans allow you to use out-of-network <a href='/glossary#service_provider' target='_blank'>service providers<\/a> (sometimes called \u201cnon-preferred providers\u201d or a \u201ctiered network\u201d), but you have to pay more to use them. If your plan allows you to go out-of-network, there may be an additional <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductible<\/a>, <a href='/glossary#copayment' target='_blank'>copayments<\/a> and <a href='/glossary#coinsurance' target='_blank'>coinsurance<\/a> and an <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a> that apply to any out-of-network services you use. If an out-of-network provider charges more than the <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a> for <a href='/glossary#covered_services' target='_blank'>covered services<\/a>, you may be responsible for paying the difference (<a href='/glossary#balance_billing' target='_blank'>balance billing<\/a>). It also may not count towards your out-of-network deductible or out-of-pocket limit."
      },
      {
        "term": "Out-of-Pocket Costs",
        "description": "Expenses you incur for medical services that your insurance company doesn't pay including <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductibles<\/a>, <a href='https://www.maine.gov/pfr/insurance/consumer/consumer_guides/pdf/consumer_guide_small_business_health_ins.pdf' target='_blank'>copayments<\/a>, <a href='https://www.maine.gov/pfr/insurance/consumer/consumer_guides/pdf/consumer_guide_small_business_health_ins.pdf' target='_blank'>coinsurance<\/a>, <a href='https://www.maine.gov/pfr/insurance/consumer/consumer_guides/pdf/consumer_guide_small_business_health_ins.pdf' target='_blank'>balance billing<\/a> along with any costs you incur for <a href='https://www.maine.gov/pfr/insurance/consumer/consumer_guides/pdf/consumer_guide_small_business_health_ins.pdf' target='_blank'>excluded services<\/a>."
      },
      {
        "term": "Out-of-Pocket Limit",
        "description": "The most you'll have to pay in a <a href='/glossary#plan_year' target='_blank'>plan year<\/a> for <a href='/glossary#covered_services' target='_blank'>covered services<\/a> before your <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> company pays 100 percent. After you spend this amount on <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductibles<\/a>, <a href='/glossary#copayment' target='_blank'>copayments<\/a>, and <a href='/glossary#coinsurance' target='_blank'>coinsurance<\/a>, your health insurance pays 100 percent of the <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a> for covered services. <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>Premiums<\/a> don't count towards your out-of-pocket limit."
      },
      {
        "term": "Out-of-Pocket Maximum",
        "description": "Also known as <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a>."
      },
      {
        "term": "Outpatient Care",
        "description": "Diagnosis or treatment in a hospital or medical facility that typically doesn't include an overnight stay. Examples include but aren't limited to emergency room services; lab tests or x-rays. "
      },
      {
        "term": "Part-time Employee",
        "description": "An employee who works on average, less than 30 hours a week."
      },
      {
        "term": "Patient Protection and Affordable Care Act",
        "description": "One of the health care laws commonly referred to as the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>."
      },
      {
        "term": "Payment Allowance",
        "description": "Also referred to as the <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a>."
      },
      {
        "term": "Payment Bundling",
        "description": "A payment structure where different health care providers who are treating you for the same or related conditions are paid an overall sum for taking care of your condition rather than being paid for each individual treatment, test, or procedure. Providers are rewarded for coordinating care, preventing complications and errors, and reducing unnecessary or duplicative tests and treatments."
      },
      // {
      //   "term": "Penalty",
      //   "description": "Formally known as the <a href='/glossary#individual_shared_responsibility_payment' target='_blank'>Individual Shared Responsibility Payment<\/a>."
      // },
      {
        "term": "Physician Services",
        "description": "Health care services a licensed medical physician (M.D. \u2013 Medical Doctor or D.O. \u2013 Doctor of Osteopathic Medicine) provides or coordinates."
      },
      {
        "term": "Plan Documents",
        "description": "An umbrella term that applies to documents like the <a href='/glossary#summary_of_benefits_and_coverage' target='_blank'>Summary of Benefits and Coverage<\/a> and the more detailed policy (also called a contract) with your insurance company. These documents describe <a href='/glossary#covered_services' target='_blank'>covered services<\/a>, <a href='/glossary#excluded_services' target='_blank'>excluded services<\/a>, <a href='/glossary#out-of-pocket_costs' target='_blank'>out-of-pocket costs<\/a> you must pay, and describe your obligations and the insurance company's. You can find a link to the full insurance policy at the top of the first page of the Summary of Benefits and Coverage document. "
      },
      {
        "term": "Plan Match",
        "description": "Maine Cover ME's health plan comparison tool. Plan match helps you compare and choose a plan based on the features that are most important to you. See <a class='ext' href='https://www.maine.gov/pfr/insurance/consumer/individuals_families/health/purchasing_health_insurance/shopping_health_insurance.html' target='_blank'>Plan Match for Individuals & Families<\/a>"
      },
      {
        "term": "Plan Participants",
        "description": "An umbrella term that refers to employees as well as their spouses, <a href='/glossary#domestic_partnership' target='_blank'>domestic partners<\/a> or dependents who may receive coverage through an <a href='/glossary#employer-sponsored_health_insurance' target='_blank'>employer-sponsored health plan<\/a>."
      },
      {
        "term": "Plan Type",
        "description": "Plan type impacts which doctors you can see, whether or not you can use <a href='/glossary#out-of-network' target='_blank'>out-of-network<\/a> providers or providers outside of your <a href='/glossary#service_area' target='_blank'>service area<\/a>, and how much you'll pay. Plan types available through Maine Cover ME include: <a href='/glossary#health_maintenance_organization' target='_blank'>Health Maintenance Organizations<\/a>; <a href='/glossary#exclusive_provider_organization' target='_blank'>Exclusive Provider Organizations<\/a>; <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>Preferred Provider Organizations<\/a>; and <a href='/glossary#point-of-service_plan' target='_blank'>Point of Service Plans<\/a>. "
      },
      {
        "term": "Plan Year",
        "description": "A 12-month period during which the benefits and <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premium<\/a> rates for insurance plans stay the same.  The plan year for the <a href='/glossary#individual_&_family_health_insurance' target='_blank'>Individual & Family marketplace<\/a> is the same as the calendar year, even if you\u2019re not enrolled for the whole calendar year.  If you\u2019re enrolled in a <a href='/glossary#group_health_plan' target='_blank'>group health plan<\/a> through an employer, your plan year may not be on a calendar year basis. "
      },
      {
        "term": "Plastic Surgery",
        "description": "An elective medical procedure to improve your appearance that usually isn't covered by <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> such as a face lift or rhinoplasty. There are some exceptions for surgeries that are considered <a href='/glossary#medically_necessary' target='_blank'>medically necessary<\/a> or classified as <a href='/glossary#reconstructive_surgery' target='_blank'>reconstructive surgery<\/a>."
      },
      {
        "term": "Platinum Health Plan",
        "description": "Platinum Health Plans pay 90 percent of <a href='/glossary#in-network' target='_blank'>in-network<\/a> expenses for an average population of consumers. The <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> are typically among the highest, but the <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a> of what you'll pay before the plan starts paying is usually the lowest and the plan may not have a <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductible<\/a> at all. <a href='/glossary#metal_level' target='_blank'>Metal levels<\/a> only focus on what the plan is expected to pay, and do NOT reflect the quality of health care or <a href='/glossary#service_provider' target='_blank'>service providers<\/a> available through the health insurance plan. Once you meet your in-network out-of-pocket limit for the <a href='/glossary#plan_year' target='_blank'>plan year<\/a>, plans pay 100 percent of the <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a> for <a href='/glossary#covered_services' target='_blank'>covered services<\/a>. "
      },
      {
        "term": "Point-of-Service Plan",
        "description": "A type of health plan that's a combination of a <a href='/glossary#health_maintenance_organization' target='_blank'>Health Maintenance Organization<\/a> and a <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>Preferred Provider Organization Plan<\/a>. Typically, it has a network that functions like a HMO \u2013 you pick a <a href='/glossary#primary_care_physician' target='_blank'>primary care physician<\/a>, who manages and coordinates your care <a href='/glossary#in-network' target='_blank'>in-network<\/a>. Similar to a PPO, you can use an <a href='/glossary#out-of-network' target='_blank'>out-of-network<\/a> <a href='/glossary#service_provider' target='_blank'>service provider<\/a> with a <a href='/glossary#referral' target='_blank'>referral<\/a>."
      },
      {
        "term": "POS",
        "description": "The acronym for <a href='/glossary#point-of-service_plan' target='_blank'>Point-of-Service Plan<\/a> \u2013 a <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> <a href='/glossary#plan_type' target='_blank'>plan type<\/a>."
      },
      {
        "term": "PPACA",
        "description": "The acronym for the federal health laws more commonly called the <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a>."
      },
      {
        "term": "PPO",
        "description": "The acronym for <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>Preferred Provider Organization<\/a> \u2013 a <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> <a href='/glossary#plan_type' target='_blank'>plan type<\/a>."
      },
      {
        "term": "Pre-Authorization",
        "description": "Approvals required by your insurance company prior to receiving some services. Your <a href='/glossary#plan_documents' target='_blank'>plan documents<\/a> spell out which services require pre-authorization. Failure to obtain it may mean your insurance company won't help pay for the service or procedure. For <a href='/glossary#in-network' target='_blank'>in-network<\/a> care, your doctor will typically obtain any required approvals. For <a href='/glossary#out-of-network' target='_blank'>out-of-network<\/a> care, you may have to obtain the approvals yourself. "
      },
      {
        "term": "Pre-Existing Condition",
        "description": "A <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'> pre-existing condition<\/a> health problem you had before your health coverage begins. Under the Affordable Care Act, health insurance companies can\u2019t refuse to cover you or charge you more just because you have a pre-existing condition."
      },
      {
        "term": "Preferred Broker",
        "description": "Preferred Brokers are trusted partners of Maine Cover ME that complete additional training to expand their expertise, and have committed to meet responsive service requirements. Preferred Brokers are licensed under Maine law to sell <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> through Maine Cover ME to individuals, families, small businesses and their employees. They can recommend plans or <a href='/glossary#plan_type' target='_blank'>plan types<\/a>, and perform activities on behalf of their clients as part of their professional licensing and training. There is no cost to use a Preferred Broker."
      },
      // Rearranged so RegExp searches for larger terms first
      {
        "term": "Preferred Provider Organization",
        "description": "A PPO (Preferred Provider Organization) plan covers care from <a href='/glossary#in-network' target='_blank'>in-network<\/a> and <a href='/glossary#out-of-network' target='_blank'>out-of-network<\/a> providers. You pay less if you use providers that belong to the plan\u2019s network. You can use providers outside of the network for an additional cost. "
      },
      {
        "term": "Preferred Provider",
        "description": "Another way of saying a provider is <a href='/glossary#in-network' target='_blank'>in-network<\/a>."
      },
      // Rearranged so RegExp searches for larger terms first
      {
        "term": "Premium Tax Credit",
        "description": "A less formal way of saying <a href='/glossary#advance_premium_tax_credit' target='_blank'>Advance Premium Tax Credit<\/a>."
      },
      {
        "term": "Premium",
        "description": "The amount you must pay to have a <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> contract or plan. You and\/or your employer pay it monthly. Premium costs are calculated based on your age, not on your <a href='https://www.maine.gov/pfr/insurance/glossary.html#preexistingcondition' target='_blank'>health status<\/a>. "
      },
      {
        "term": "Prescription Drug Coverage",
        "description": "All plans available through Maine Cover ME include prescription drug coverage, but that doesn't mean that all plans cover your prescriptions. When you use Maine Cover ME's <a href='https://www.maine.gov/pfr/insurance/consumer/individuals_families/health/purchasing_health_insurance/shopping_health_insurance.html' target='_blank'>Plan Match<\/a> tool, you'll have the opportunity to enter the names of your <a href='/glossary#prescription_drugs' target='_blank'>prescription drugs<\/a> and see which plans provide coverage. You should also check the insurance company's <a href='/glossary#formulary' target='_blank'>formulary<\/a>."
      },
      {
        "term": "Prescription Drugs",
        "description": "A medication that legally requires your doctor to write an authorization for you to use it before a pharmacy can sell it to you. Most <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plans cover some prescription drug costs. If you take medications that require a prescription from your doctor, you'll want to make sure that the health plan you choose covers your specific medications by checking Maine Cover ME's <a href='https://www.maine.gov/pfr/insurance/consumer/individuals_families/health/purchasing_health_insurance/shopping_health_insurance.html' target='_blank'>Plan Match<\/a> tool and the insurance company's <a href='/glossary#formulary' target='_blank'>formulary<\/a>."
      },
      {
        "term": "Preventive Services",
        "description": "Health care to prevent or detect illness or other health problems at an early stage, when treatment is likely to work best. All health plans available through Maine Cover ME include certain preventive services at no cost to you. When you use Maine Cover ME's <a href='https://www.maine.gov/pfr/insurance/consumer/individuals_families/health/purchasing_health_insurance/shopping_health_insurance.html' target='_blank'>Plan Match<\/a> tool, you'll find information on preventive services included in your plan when you select the 'Plan Details' page."
      },
      // Rearranged so RegExp searches for larger terms first
      {
        "term": "Primary Care Physician",
        "description": "A physician (M.D. \u2013 Medical Doctor or D.O. \u2013 Doctor of Osteopathic Medicine) who directly provides or coordinates a range of health care services for a patient. Some health plans require that you select an <a href='/glossary#in-network' target='_blank'>in-network<\/a> primary care physician for routine care and coordination of any specialized care. "
      },
      {
        "term": "Primary Care Provider",
        "description": "Doctors, nurses, nurse practitioners, and physician assistants. "
      },
      {
        "term": "Primary Care",
        "description": "Health services that cover a range of prevention, wellness, and treatment for common illnesses. "
      },
      {
        "term": "Prior Authorization",
        "description": "Another way of saying <a href='/glossary#pre-authorization' target='_blank'>Pre-Authorization<\/a>."
      },
      {
        "term": "Private Health Insurance",
        "description": "<a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>Health insurance<\/a> offered by an employer, purchased through an insurance company or through a health insurance marketplace like the private plans available through Maine Cover ME. "
      },
      {
        "term": "QHP",
        "description": "The acronym for <a href='/glossary#qualified_health_plan' target='_blank'>Qualified Health Plan<\/a>."
      },
      {
        "term": "QLE",
        "description": "The acronym for <a href='/glossary#qualifying_life_event' target='_blank'>Qualifying Life Event<\/a>."
      },
      {
        "term": "Qualified Health Plan",
        "description": "A plan purchased through a <a href='https://www.maine.gov/dhhs/programs-services/health-insurance_marketplace' target='_blank'>health insurance marketplace<\/a>, such as the <a href='/glossary#private_health_insurance' target='_blank'>private plans<\/a> available through Maine Cover ME."
      },
      {
        "term": "Qualified Medical Expenses",
        "description": "The same types of services and products that generally can be deducted as medical expenses on your federal tax return. <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>Deductibles<\/a>, <a href='/glossary#copayment' target='_blank'>copayments<\/a>, <a href='/glossary#coinsurance' target='_blank'>coinsurance<\/a> and <a href='/glossary#prescription_drugs' target='_blank'>prescription drugs<\/a> are examples. "
      },
      {
        "term": "Qualifying Life Event",
        "description": "If you have a life change, such as but not limited to getting married, having a baby or losing your employer-sponsored insurance, you may be able to get <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> coverage outside of the annual <a href='/glossary#open_enrollment' target='_blank'>open enrollment<\/a> period, or make changes to your plan during the year. This is called <a href='/glossary#special_enrollment_period' target='_blank'>special enrollment<\/a>. The deadlines for reporting the life change to Maine Cover ME and enrolling through special enrollment are different in the Individual & Family and Small Business marketplaces. See <a class='ext' href='' target='_blank'>Individual & Family life changes and deadlines<\/a> or <a class='ext' href='https:\/\/dchealthlink.com\/sites\/default\/files\/v2\/forms\/Qualifying_Life_Events_QLEs_Enrolling_in_a_New_Plan.pdf' target='_blank'>employer-sponsored insurance life changes and deadlines<\/a> for more information. "
      },
      {
        "term": "Rate Review",
        "description": "the State of Maine's <a href='/glossary#department_of_insurance&#44;_securities_and_banking' target='_blank'>Department of Insurance, Security & Banking<\/a> reviews <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> rates that insurance company's submit for approval to determine if rate increases or decreases will be approved or rejected. Learn more about the <a class='ext' href='http:\/\/\/service\/health-insurance-rate-review' target='_blank'>rate review process<\/a>. "
      },
      {
        "term": "RCA",
        "description": "The acronym for the State of Maine\u2019s <a href='/glossary#refugee_cash_assistance_program' target='_blank'>Refugee Cash Assistance Program<\/a>."
      },
      {
        "term": "Reconstructive Surgery",
        "description": "Surgery and follow-up treatment needed to correct or improve a part of the body because of birth defects, accidents, injuries or medical conditions."
      },
      {
        "term": "Reference Plan",
        "description": "Employers that offer <a href='/glossary#plan_participants' target='_blank'>plan participants<\/a> a choice of plans (by <a href='/glossary#metal_level' target='_blank'>metal level<\/a> or insurance company) choose one plan among them to cap costs. This is the reference plan. Employer contributions towards <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> are determined by the cost of this plan regardless of which plans participants select. <a class='ext' href='https:\/\/dchealthlink.com\/sites\/default\/files\/v2\/pdf\/reference-plan-guide.pdf' target='_blank'>Download our guide (PDF)<\/a>"
      },
      {
        "term": "Referral",
        "description": "A written recommendation from a doctor for you to see a specialist or get certain medical services. Some health plans require you to have a <a href='/glossary#primary_care_physician' target='_blank'>primary care physician<\/a> and get a written referral before you can get medical care from anyone else (except in an emergency). If you don\u2019t get a referral first, the plan may not pay for the services."
      },
      {
        "term": "Refugee Cash Assistance Program",
        "description": "This Maine's Office of Refugee Resettlement serves to transition Maine Refugees from dependency on public assistance to self-sufficiency. Cash assistance is one of many services offered to refugees in the State of Maine. Learn more about <a class='ext' href='http:\/\/\/service\/refugee-assistance' target='_blank'>refugee assistance in the State of Maine<\/a>. "
      },
      {
        "term": "Rehabilitation Services",
        "description": "Health care services such as occupational, physical, speech or psychiatric therapy that focus on helping retain, recover or enhance daily living skills that were lost or damaged because of an illness, injury or disability. Examples include physical and speech therapy following a stroke. "
      },
      {
        "term": "SBC",
        "description": "The acronym for <a href='/glossary#summary_of_benefits_and_coverage' target='_blank'>Summary of Benefits and Coverage<\/a>."
      },
      {
        "term": "Second Lowest Cost Silver Plan",
        "description": "The <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premium<\/a> you would be charged for the second lowest cost <a href='/glossary#silver_health_plan' target='_blank'>silver health plan<\/a> available through Maine Cover ME is used to calculate the amount of any <a href='/glossary#advance_premium_tax_credit' target='_blank'>advance premium tax credit<\/a> you could be eligible to receive, even when this isn\u2019t the plan in which you enroll. Following enrollment, this amount is reported on <a href='/glossary#irs_form_1095-a' target='_blank'>IRS Form 1095-A<\/a>."
      },
      {
        "term": "Service Area",
        "description": "Some health plans only provide <a href='/glossary#covered_services' target='_blank'>covered services<\/a> within a specific geographic area (except in an emergency) using <a href='/glossary#in-network' target='_blank'>in-network<\/a> <a href='/glossary#service_provider' target='_blank'>service providers<\/a>. "
      },
      {
        "term": "Service Provider",
        "description": "A doctor, health care professional, or health care facility licensed, certified or accredited as required by state law. "
      },
      {
        "term": "SHOP",
        "description": "The acronym for <a href='/glossary#small_business_health_options_program' target='_blank'>Small Business Health Options Program<\/a>."
      },
      {
        "term": "Silver Health Plan",
        "description": "Silver Health Plans pay 70 percent of <a href='/glossary#in-network' target='_blank'>in-network<\/a> expenses for an average population of consumers. The <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> are typically lower, but the <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a> of what you'll pay before the plan starts paying is higher. If you qualify for <a href='/glossary#cost-sharing_reduction' target='_blank'>cost-sharing reductions<\/a> and choose a silver plan, you'll have very low out-of-pocket expenses. <a href='/glossary#metal_level' target='_blank'>Metal levels<\/a> only focus on what the plan is expected to pay, and do NOT reflect the quality of health care or <a href='/glossary#service_provider' target='_blank'>service providers<\/a> available through the <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan. Once you meet your in-network out-of-pocket limit for the <a href='/glossary#plan_year' target='_blank'>plan year<\/a>, plans pay 100 percent of the <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a> for <a href='/glossary#covered_services' target='_blank'>covered services<\/a>. "
      },
      {
        "term": "Silver Plan",
        "description": "Silver Health Plans pay 70 percent of <a href='/glossary#in-network' target='_blank'>in-network<\/a> expenses for an average population of consumers. The <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> are typically lower, but the <a href='/glossary#out-of-pocket_limit' target='_blank'>out-of-pocket limit<\/a> of what you'll pay before the plan starts paying is higher. If you qualify for <a href='/glossary#cost-sharing_reduction' target='_blank'>cost-sharing reductions<\/a> and choose a silver plan, you'll have very low out-of-pocket expenses. <a href='/glossary#metal_level' target='_blank'>Metal levels<\/a> only focus on what the plan is expected to pay, and do NOT reflect the quality of health care or <a href='/glossary#service_provider' target='_blank'>service providers<\/a> available through the <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan. Once you meet your in-network out-of-pocket limit for the <a href='/glossary#plan_year' target='_blank'>plan year<\/a>, plans pay 100 percent of the <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a> for <a href='/glossary#covered_services' target='_blank'>covered services<\/a>. "
      },
      {
        "term": "SLCSP",
        "description": "The acronym for <a href='/glossary#second_lowest_cost_silver_plan' target='_blank'>Second Lowest Cost Silver Plan<\/a>."
      },
      // Rearranged so RegExp searches for larger terms first
      {
        "term": "Small Business Health Options Program",
        "description": "The name used to describe the federal and state <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance marketplaces<\/a> for small businesses. "
      },
      {
        "term": "Small Business Tax Credit",
        "description": "Small businesses that have fewer than 25 <a href='/glossary#full-time_equivalent_employee' target='_blank'>full-time equivalent employees<\/a>, pay an average wage of less than $50,000 a year, and pay at least half of employee <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> are eligible for a federal tax credit when they purchase health insurance through Maine Cover ME. Use the <a class='ext' href='https:\/\/dchealthlink.com\/smallbusiness\/tax-credit-calculator' target='_blank'>small business tax credit calculator<\/a> to learn more and estimate your credit."
      },
      {
        "term": "Small Business",
        "description": "At Maine Cover ME, a small business is defined as having at least 1 but no more than 50 <a href='/glossary#full-time_equivalent_employee' target='_blank'>full-time equivalent employees<\/a>. "
      },
      {
        "term": "SNAP",
        "description": "The acronym for <a href='https://www.maine.gov/dhhs/programs-services/food-nutrition' target='_blank'>Supplemental Nutrition Assistance Program<\/a>."
      },
      // Rearranged so RegExp searches for larger terms first
      {
        "term": "Social Security Administration",
        "description": "The federal agency that assigns social security numbers; administers the retirement, survivors, and disability insurance programs known as <a href='/glossary#social_security' target='_blank'>Social Security<\/a>; and administers the <a href='/glossary#supplemental_security_income' target='_blank'>Supplemental Security Income<\/a> program for the aged, blind, and disabled."
      },
      {
        "term": "Social Security",
        "description": "A federal benefits program that taxes your income while you work, so that when you retire or if you become disabled, you, your spouse and your dependent children receive monthly benefits based on your reported earnings. Survivors can also collect benefits if you die. "
      },
      {
        "term": "Special Enrollment Period",
        "description": "Outside the <a href='/glossary#open_enrollment' target='_blank'>open enrollment<\/a> season, you can enroll in a <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plan only if you qualify for a <a href='/glossary#special_enrollment_period' target='_blank'>special enrollment<\/a>. You qualify if you have certain <a href='/glossary#qualifying_life_event' target='_blank'>qualifying life events<\/a>, like moving to the State of Maine, getting married, having a baby, losing other health coverage and other circumstances. "
      },
      {
        "term": "Specialist",
        "description": "A <a href='/glossary#service_provider' target='_blank'>service provider<\/a> with medical expertise, education and training in a particular practice area. Examples include: dermatologists, ear\/nose\/throat specialists, oncologists and cardiologists. Some health plans require a <a href='/glossary#referral' target='_blank'>referral<\/a> from your <a href='/glossary#primary_care_physician' target='_blank'>primary care physician<\/a> to see a specialist. "
      },
      {
        "term": "SSA",
        "description": "The acronym for <a href='/glossary#social_security_administration' target='_blank'>Social Security Administration<\/a>."
      },
      {
        "term": "SSI",
        "description": "The acronym for the <a href='/glossary#supplemental_security_income' target='_blank'>Supplemental Security Income<\/a> program."
      },
      {
        "term": "Stand-alone Dental Plan",
        "description": "A dental insurance plan not included in your health plan. Dental care for adults is typically not included in medical plans. "
      },
      {
        "term": "Stand-alone Vision Plan",
        "description": "A vision insurance plan not included in your health plan. Vision care for adults is not always included in medical plans. "
      },
      {
        "term": "Standard Plan",
        "description": "Each health insurance company offers a standard plan at each <a href='/glossary#metal_level' target='_blank'>metal level<\/a>. Benefits and cost-sharing are the same, but monthly <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a> and <a href='/glossary#network' target='_blank'>network<\/a> options may be different. This makes it easier for consumers to do a side-by-side comparison of plans at the same metal level offered by different insurers. "
      },
      {
        "term": "State Continuation Coverage",
        "description": "Small businesses in the State of Maine with 20 or fewer employees that offer health benefits, are required to provide 3 months of continuing coverage to terminated employees, except for terminations arising from gross misconduct.  The employer is required to provide notice to the employee within 15 days after the date that coverage would terminate of the employee\u2019s rights to continuing coverage.  The employee must confirm they want to keep coverage, and pay the <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premium<\/a> within 45 days after the date the coverage would otherwise terminate. "
      },
      {
        "term": "Step Therapy",
        "description": "A form of <a href='/glossary#pre-authorization' target='_blank'>pre-authorization<\/a> some plans apply to certain <a href='/glossary#prescription_drugs' target='_blank'>prescription drugs<\/a> to control risks and costs where the safest, most cost effective drug for a medical condition is prescribed first, before treatment can be \u201cstepped up\u201d with more expensive and\/or riskier drugs. "
      },
      {
        "term": "Subsidy",
        "description": "An informal name for the <a href='/glossary#advance_premium_tax_credit' target='_blank'>advance premium tax credit<\/a> or <a href='/glossary#cost-sharing_reduction' target='_blank'>cost-sharing reductions<\/a>."
      },
      {
        "term": "Summary of Benefits and Coverage",
        "description": "All plans available through Maine Cover ME include a short, plain language PDF document that provides an overview of <a href='/glossary#covered_services' target='_blank'>covered services<\/a>, <a href='/glossary#excluded_services' target='_blank'>excluded services<\/a>, a short glossary of terms, <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductibles<\/a>, <a href='/glossary#copayment' target='_blank'>copayments<\/a> and <a href='/glossary#coinsurance' target='_blank'>coinsurance<\/a> for <a href='/glossary#in-network' target='_blank'>in-network<\/a> and <a href='/glossary#out-of-network' target='_blank'>out-of-network<\/a> services. The SBC is standardized so that you can make an apples-to-apples comparison among plans, and includes what the plan will pay in two common medical situations. You can find the SBC on the 'Plan Details' page when using Maine Cover ME's <a href='https://www.maine.gov/pfr/insurance/consumer/individuals_families/health/purchasing_health_insurance/shopping_health_insurance.html' target='_blank'>Plan Match<\/a> tool. "
      },
      {
        "term": "Supplemental Nutrition Assistance Program",
        "description": "The name for the federal food stamp program. the State of Maines\u2019 SNAP program helps low-income residents and families buy the food they need for good health. Learn more about <a class='ext' href='https://www.maine.gov/dhhs/programs-services/food-nutrition' target='_blank'>how to apply for SNAP<\/a>. "
      },
      {
        "term": "Supplemental Security Income",
        "description": "A federal program that provides cash assistance for food, clothing and shelter for disabled or blind adults, children, and people 65 years or older without disabilities who have limited income or resources. This is not the same as <a href='/glossary#social_security' target='_blank'>social security<\/a> retirement or disability benefits, and some people may qualify for both. Learn more about <a class='ext' href='https:\/\/www.ssa.gov\/ssi\/' target='_blank'>how to apply for SSI<\/a>. "
      },
      {
        "term": "TANF",
        "description": "The acronym for the State of Maine\u2019s <a href='/glossary#temporary_cash_assistance_for_needy_families' target='_blank'>Temporary Cash Assistance for Needy Families<\/a> program."
      },
      {
        "term": "Tax Credit",
        "description": "An informal way of referring to the <a href='/glossary#advance_premium_tax_credit' target='_blank'>Advance Premium Tax Credit<\/a> for individuals or families or the <a href='/glossary#small_business_tax_credit' target='_blank'>Small Business Tax Credit<\/a>."
      },
      {
        "term": "Tax Dependent",
        "description": "A person (other than you or your spouse) such as a child, parent or other relative, for whom you're entitled to claim a personal exemption on your federal tax return. If you're unsure, the IRS has a tool to help determine <a class='ext' href='https:\/\/www.irs.gov\/uac\/who-can-i-claim-as-a-dependent' target='_blank'>who you can claim as a dependent<\/a>. "
      },
      {
        "term": "Tax Equity and Fiscal Responsibility Act",
        "description": "A more formal name for the <a href='/glossary#katie_beckett_program' target='_blank'>Katie Beckett Program<\/a>."
      },
      {
        "term": "Tax Penalty",
        "description": "An informal name for the penalty you may pay if you go without health insurance, known as the <a href='/glossary#individual_shared_responsibility_payment' target='_blank'>Individual Shared Responsibility Payment<\/a>."
      },
      {
        "term": "TEFRA",
        "description": "The acronym for the Tax Equity Fiscal Responsibility Act, also known as the <a href='/glossary#katie_beckett_program' target='_blank'>Katie Beckett Program<\/a>."
      },
      {
        "term": "Temporary Cash Assistance for Needy Families",
        "description": "Provides cash assistance to needy families with dependent children when available resources do not fully address the family's needs and while preparing program participants for independence through work. Learn more about <a class='ext' href='http:\/\/\/service\/temporary-cash-assistance-needy-families-tanf' target='_blank'>financial and technical eligibility requirements<\/a> for Maine residents."
      },
      {
        "term": "TTY",
        "description": "A telephone and text communications protocol for people with hearing or speech difficulties. "
      },
      {
        "term": "UCR",
        "description": "The acronym for <a href='/glossary#usual&#44;_customary_and_reasonable' target='_blank'>Usual&#44; Customary and Reasonable<\/a>."
      },
      {
        "term": "Unaffordable Coverage",
        "description": "A standard applied to <a href='/glossary#employer-sponsored_health_insurance' target='_blank'>employer-sponsored health insurance<\/a>. See the definition for <a href='/glossary#affordable_coverage' target='_blank'>affordable coverage<\/a>."
      },
      {
        "term": "Urgent Care",
        "description": "A situation that requires immediate medical attention, but isn't life threatening or a severe bodily injury. "
      },
      {
        "term": "US Department of Health and Human Services",
        "description": "A cabinet-level federal department charged with protecting and enhancing the health and well-being of all Americans. The <a href='/glossary#affordable_care_act' target='_blank'>Affordable Care Act<\/a> is administered by HHS and many of its agencies."
      },
      {
        "term": "Usual, Customary and Reasonable",
        "description": "The amount <a href='/glossary#service_provider' target='_blank'>service providers<\/a> typically charge for a medical service in your geographic area. Sometimes it's the same as the <a href='/glossary#allowed_amount' target='_blank'>allowed amount<\/a>, or is used by your insurance company to determine what an <a href='/glossary#out-of-network' target='_blank'>out-of-network<\/a> service provider will be paid for <a href='/glossary#covered_services' target='_blank'>covered services<\/a> if your plan allows you to go out-of-network."
      },
      {
        "term": "Waiver of Coverage",
        "description": "Applies only to <a href='/glossary#employer-sponsored_health_insurance' target='_blank'>employer-sponsored health plans<\/a>. Employees have the option of waiving medical coverage offered by their employer. Employees who waive coverage don\u2019t count towards the minimum participation requirements to create a health benefits program through Maine Cover ME. Employees who believe they may qualify for <a href='https://www.maine.gov/dhhs/ofi/programs-services/health-care-assistance' target='_blank'>Medicaid<\/a> or help paying for coverage in the <a href='/glossary#individual_&_family_health_insurance' target='_blank'>Individual & Family marketplace<\/a> should apply for <a href='/glossary#financial_assistance' target='_blank'>financial assistance<\/a> before waiving coverage offered by an employer."
      },
      {
        "term": "Well-Baby\/Well-Child Care",
        "description": "All <a href='https://www.maine.gov/dhhs/programs-services/health-insurance' target='_blank'>health insurance<\/a> plans available through Maine Cover ME are required by federal law to include certain <a href='/glossary#preventive_services' target='_blank'>preventive services<\/a> for children under the age of 18 at no cost to you if you use an <a href='/glossary#in-network' target='_blank'>in-network<\/a> <a href='/glossary#service_provider' target='_blank'>service provider<\/a>. This includes well-baby\/well-child visits to a doctor or nurse to make sure your child is healthy and developing normally, standard tests and assessments and recommended immunizations. The number of visits covered depends on your child's age, and does not include visits when your child is sick or injured. Check with your insurance company to understand what's covered and to get the most out of your benefits. "
      },
      {
        "term": "Wellness Program",
        "description": "An optional incentive program sometimes offered by employers or insurance companies to improve health and fitness. Examples include programs that promote weight loss, smoking cessation, or preventive screenings. "
      },
      {
        "term": "Yearly Cost Estimate for Health Coverage",
        "description": "A feature of Maine Cover ME's <a href='/glossary#plan_match' target='_blank'>Plan Match<\/a> tool that shows the estimated amount you might pay in a given year for <a href='https://www.maine.gov/pfr/insurance/glossary.html#p' target='_blank'>premiums<\/a>, <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductibles<\/a>, <a href='https://www.maine.gov/pfr/insurance/glossary.html#c' target='_blank'>copayments<\/a> and <a href='https://www.maine.gov/pfr/insurance/glossary.html#c' target='_blank'>coinsurance<\/a> based on the number of people covered, your health status and any expected medical procedures. "
      },
      {
        "term": "Zero Cost Sharing Plan",
        "description": "<a href='/glossary#federally_recognized_tribe' target='_blank'>Federally recognized Tribes<\/a> and <a href='/glossary#alaskan_native' target='_blank'>Alaska Native<\/a> Claims Settlement Act (ANCSA) Corporation shareholders whose income is at or below 300 percent of the <a href='/glossary#federal_poverty_level' target='_blank'>federal poverty level<\/a> are eligible for a zero cost sharing plan. With this plan, there are no <a href='https://www.maine.gov/pfr/insurance/glossary.html#c' target='_blank'>copayments<\/a>, <a href='https://www.maine.gov/pfr/insurance/glossary.html#d' target='_blank'>deductibles<\/a> or <a href='https://www.maine.gov/pfr/insurance/glossary.html#c' target='_blank'>coinsurance<\/a> when care is received from Indian health care providers, which include health programs operated by the <a href='https://www.ihs.gov/findhealthcare/' target='_blank'>Indian Health Service<\/a>, tribes and tribal organizations, and urban Indian organizations. This is also true when receiving <a href='/glossary#essential_health_benefits' target='_blank'>essential health benefits<\/a> through a Maine Cover ME plan, and you won't need a <a href='/glossary#referral' target='_blank'>referral<\/a> from an Indian health care provider to receive these benefits. Zero cost sharing is available for any <a href='/glossary#metal_level' target='_blank'>metal level<\/a> plan."
      }
    ]

    // this allows the :contains selector to be case insensitive
    $.expr[":"].contains = $.expr.createPseudo(function (arg) {
      return function (elem) {
        return $(elem).text().toLowerCase().indexOf(arg.toLowerCase()) >= 0;
      };
    });
    $(terms).each(function(i, term) {
        // finds the first instance of the term on the page
        // var matchingEl = $('.run-glossary:contains(' + term.term + ')').first();
        // if (matchingEl.length) {
        // finds every instance of the term on the page
        $('.run-glossary:contains(' + term.term + ')').each(function(i, matchingEl) {
          // matches the exact or plural term
          var termRegex    = new RegExp("\\b(" + term.term + "[s]?)\\b", "gi");
          var popoverRegex = new RegExp("(<span class=\"glossary\".+?<\/span>)");
          var description  = term.description;
          var newElement   = "";
          $(matchingEl).html().toString().split(popoverRegex).forEach(function(text){
            // if a matching term has not yet been given a popover, replace it with the popover element
            if (!text.includes("class=\"glossary\"")) {
              newElement += text.replace(termRegex, '<span class="glossary" data-toggle="popover" data-placement="auto top" data-trigger="click focus" data-boundary="window" data-fallbackPlacement="flip" data-html="true" data-content="' + description + '" data-title="' + term.term + '<button data-dismiss=\'modal\' type=\'button\' class=\'close\' aria-label=\'Close\' onclick=\'hideGlossaryPopovers()\'></button>">$1</span>');
            }
            else {
              // if the term has already been given a popover, do not search it again
              newElement += text;
            }
            $(matchingEl).html(newElement);
          });
        });
    });
    $('[data-toggle="popover"]').popover();

    // Because of the change to popover on click instead of hover, you need to
    // manually close each popover. This will close others if you click to open one
    // or click outside of a popover.

    $(document).click(function(e){
      if (e.target.className == 'glossary') {
        e.preventDefault();
        $('.glossary').not($(e.target)).popover('hide');
      }
      else if (!$(e.target).parents('.popover').length) {
        $('.glossary').popover('hide');
      }
    });


    //$.ajax({
    //  cache: true,
    //  type: 'json',
    //  url: '/glossary/json'
    //}).done(function(data, textStatus, jqXHR) {
    //});
  }
}


function hideGlossaryPopovers() {
  $('.glossary').popover('hide');
}
