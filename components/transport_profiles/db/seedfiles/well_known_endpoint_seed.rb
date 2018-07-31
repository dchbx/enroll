endpoints = [
    { title: "House of Representatives member invoice outbound",   key: :hr_members_invoice_outbound,      site_key: :dchbx, market_kind: :aca_congress, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "House of Representatives member statement outbound", key: :hr_members_statement_outbound,    site_key: :dchbx, market_kind: :aca_congress, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "House of Representatives staff invoice outbound",    key: :hr_staff_invoice_outbound,        site_key: :dchbx, market_kind: :aca_congress, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "House of Representatives staff statement outbound",  key: :hr_staff_statement_outbound,      site_key: :dchbx, market_kind: :aca_congress, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "Senate invoice outbound",                            key: :senate_member_invoice_outbound,   site_key: :dchbx, market_kind: :aca_congress, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "Senate statement outbound",                          key: :senate_member_statement_outbound, site_key: :dchbx, market_kind: :aca_congress, uri: "sftp://blah.com/folder", credentials: [] },

    { title: "Premium Billing Provider SHOP employer group file outbound",        key: :pbp_aca_shop_employer_group_outbound,   site_key: :cca, market_kind: :aca_shop, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "Premium Billing Provider SHOP invoice inbound",                     key: :pbp_aca_shop_employer_invoice_inbound,  site_key: :cca, market_kind: :aca_shop, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "Premium Billing Provider SHOP 820 payment remittance inbound",      key: :pbp_aca_shop_820_inbound,               site_key: :cca, market_kind: :aca_shop, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "Premium Billing Provider SHOP 834 initial enrollment outbound",     key: :pbp_aca_shop_834_initial_outbound,      site_key: :cca, market_kind: :aca_shop, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "Premium Billing Provider SHOP 834 maintenance enrollment outbound", key: :pbp_aca_shop_834_maintenance_outbound,  site_key: :cca, market_kind: :aca_shop, uri: "sftp://blah.com/folder", credentials: [] },

    { title: "Carrier SHOP employer group file inbound",   key: :carrier_aca_shop_employer_group_inbound,   site_key: :cca, market_kind: :aca_shop, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "Carrier SHOP employer group file outbound",  key: :carrier_aca_shop_employer_group_outbound,  site_key: :cca, market_kind: :aca_shop, uri: "sftp://blah.com/folder", credentials: [] },

#    { title: "SHOP Analytics/Business Intelligence report outbound",  key: :aca_shop_analytics_outbound,  site_key: :cca, market_kind: :aca_shop, uri: "sftp://blah.com/folder", credentials: [], },
#    { title: "SHOP Analytics/Business Intelligence report archive", key: :aca_shop_analytics_archive,         site_key: :cca, market_kind: :aca_shop, uri: "aws3://blah.com/folder", credentials: [], },

    { title: "SHOP Employer invoice path",                          key: :aca_shop_employer_invoice_path,     site_key: :cca, market_kind: :aca_shop, uri: "aws3://blah.com/folder", credentials: [] },
    { title: "SHOP Employer invoice archive",                       key: :aca_shop_employer_invoice_archive,  site_key: :cca, market_kind: :aca_shop, uri: "aws3://blah.com/folder", credentials: [] },

    { title: "Print vendor outbound", key: :print_vendor_outbound, site_key: :cca,    market_kind: :any, uri: "sftp://blah.com/folder", credentials: [] },
    { title: "Print vendor outbound", key: :print_vendor_outbound, site_key: :dchbx,  market_kind: :any, uri: "sftp://blah.com/folder", credentials: [] },

    { title: "Email outbound", key: :email_outbound, site_key: :cca,    market_kind: :any, uri: "smtp://blah.com/folder", credentials: [] },
    { title: "Email outbound", key: :email_outbound, site_key: :dchbx,  market_kind: :any, uri: "smtp://blah.com/folder", credentials: [] },
    
    { title: "Legacy Data Extract Archive", key: :aca_legacy_data_extracts_archive , site_key: :cca, market_kind: :any, uri: "s3://bucket@whatever", credentials: [] },
    { title: "Legacy Data Extracts", key: :aca_legacy_data_extracts, site_key: :cca, market_kind: :any, uri: "s3://bucket@whatever", credentials: [] },
    
    { title: "Internal Artifact Transport", key: :aca_internal_artifact_transport, site_key: :cca, market_kind: :any, uri: "s3://bucket@whatever", credentials: [] }

  ]

  # endpoints.each { |endpoint| WellKnown_endpoint.create!(endpoint)}
