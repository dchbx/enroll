puts "*"*80
puts "::: Generating MA Carriers:::"

hbx_office = OfficeLocation.new(
    is_primary: true,
    address: {kind: "work", address_1: "address_placeholder", address_2: "address_2", city: "City", state: "St", zip: "10001" },
    phone: {kind: "main", area_code: "111", number: "111-1111"}
  )

org = Organization.new(fein: "043373331", legal_name: "BMC HealthNet Plan", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000029", abbrev: "BMCHP", hbx_carrier_id: 20003, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: false, issuer_hios_ids: ['82569'], offers_sole_source: true)

org = Organization.new(fein: "237442369", legal_name: "Fallon Health", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000037", abbrev: "FCHP", hbx_carrier_id: 20005, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: false, issuer_hios_ids: ['88806'], offers_sole_source: true)

org = Organization.new(fein: "042864973", legal_name: "Health New England", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000045", abbrev: "HNE", hbx_carrier_id: 20007, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: true, issuer_hios_ids: ['34484'])

# org = Organization.new(fein: "050513223", legal_name: "Altus", office_locations: [hbx_office])
# cp = org.create_carrier_profile(id: "53e67210eb899a4603000057", abbrev: "ALT", hbx_carrier_id: 20001, ivl_health: false, ivl_dental: false, shop_health: false, shop_dental: true, issuer_hios_ids: ['18076'])

org = Organization.new(fein: "041045815", legal_name: "Blue Cross Blue Shield MA", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000061", abbrev: "BCBS", hbx_carrier_id: 20002, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: true, issuer_hios_ids: ['42690'])

# org = Organization.new(fein: "046143185", legal_name: "Delta Dental", office_locations: [hbx_office])
# cp = org.create_carrier_profile(id: "53e67210eb899a4603000081", abbrev: "DDA", hbx_carrier_id: 20004, ivl_health: false, ivl_dental: false, shop_health: false, shop_dental: true, issuer_hios_ids: ['80538', '11821'])

org = Organization.new(fein: "042452600", legal_name: "Harvard Pilgrim Health Care", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000073", abbrev: "HPHC", hbx_carrier_id: 20008, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: false, issuer_hios_ids: ['36046'])

org = Organization.new(fein: "234547586", legal_name: "Neighborhood Health Plan", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000077", abbrev: "NHP", hbx_carrier_id: 20010, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: false, issuer_hios_ids: ['41304'])

org = Organization.new(fein: "800721489", legal_name: "Tufts Health Direct", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000085", abbrev: "THPD", hbx_carrier_id: 20011, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: false, issuer_hios_ids: ['59763'])

org = Organization.new(fein: "042674079", legal_name: "Tufts Health Plan Premier", office_locations: [hbx_office])
cp = org.create_carrier_profile(id: "53e67210eb899a4603000089", abbrev: "THPP", hbx_carrier_id: 20012, ivl_health: false, ivl_dental: false, shop_health: true, shop_dental: false, issuer_hios_ids: ['29125'])

puts "::: Generated MA Carriers :::"
puts "*"*80
