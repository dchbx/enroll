require 'rails_helper'
describe "shared/_data_table.html.erb" do

  context 'with all options on' do
    before :each do
      render partial: "shared/data_table.html.erb", locals: {
        page_header: ["Test Datatable", "url", ""],
        new_button: ["Add Datatable", "url", "request_type"],
        directions: "Use this table to review verification documents.",
        processing_text: "",
        custom_handlers: [],
        sibling_pages: [],
    	  filters: [
      		["all", "", true, []],
      		["some", "", true, [
      			["COBRA", "url", "request_type"],
      			["Termed", "url", "request_type"],
      			["Corn", "url", "request_type"]
      		]],
      		["the best ones", "", false, []],
          ["Dad", "", true, [
            ["ZZZ", "url", "request_type"],
      			["Apples", "url", "request_type"],
      			["Corn", "url", "request_type"]
            ]
          ]
      	],
      	bulk_actions: [
      		["Send Secure Message", "", true],
      		["Delete", "", false]
      	],
      	row_functions: true,
      	row_actions: [
      		["asterisk", "url", "request_type", "tooltip"],
      		["bomb", "url", "request_type", "tooltip"],
      		["asterisk", "url", "request_type", "tooltip"],
      		["bomb", "url", "request_type", "tooltip"],
          ["caret-down", "url", "request_type", "View Details"]
      	],
      	buttons_below_table: [
      		['Export CSV', 'url', 'request_type'],
      		['Print', 'url', 'request_type']
      	],
        child_rows: [true, "datatables/child_row"],
        responsive: true,
      	checkboxes: true,
      	pagination: true,
      	ordering: true,
        destroy: true,
      	info: true,
      	table_id: "verification-dataTable",
      	data_url: verifications_index_datatable_exchanges_hbx_profiles_path(:format => :json),
        columns:  [
          ["HBX ID", "hbx_id", "", [false, ""]],
          ["First name", "first_name", "", [false, ""]],
          ["Last name", "last_name", "", [false, ""]],
          ["Documents", "documents", "", [false, ""]],
          ["Due date", "due_date", "", [false, ""]],
      	  ["Status", "review_status", "", [false, ""]],
      	  ["Review", "review", "", [false, ""]],
      	  ["FedHub", "fed_hub", "", [false, ""]]
      	]
      }
    end

    it "should display the page header" do
      expect(rendered).to have_selector('h1', text: /Test Datatable/i)
    end

    it "should display the add button" do
      expect(rendered).to have_selector('a', text: /Add Datatable/i)
    end

    it "should display page directions" do
      expect(rendered).to have_selector('h4', text: /Use this table to review verification documents/i)
    end

    it "should display the first level filters" do
      expect(rendered).to have_selector('.first-level > .btn', count: 4)
    end

    it "should display the first level filters width a second-level class if they have secondary options" do
      expect(rendered).to have_selector('.first-level > .btn.second-level', count: 2)
    end

    it "should display the bulk actions drop down" do
      expect(rendered).to have_selector('.dropdown', count: 1)
    end

    it "should display the buttons below the table" do
      expect(rendered).to have_selector('.buttons-below-table .btn', count: 2)
    end

    it "should include all js functions" do
      expect(rendered).to match(/makeResponsiveTable/)
      expect(rendered).to match(/initializeFilters/)
      expect(rendered).to match(/addSelectAll/)
      expect(rendered).to match(/addBulkActions/)
      expect(rendered).to match(/addButtonsBelowTable/)
      expect(rendered).to match(/showPagination/)
      expect(rendered).to match(/moveTableLength/)
    end

    it "should display key values pairs for columns object" do
      expect(rendered).to match(/title:/)
      expect(rendered).to match(/data:/)
    end

    it "should display columns object" do
      expect(rendered).to match(/columnDefs/)
    end

    it "should include a format function for child rows" do
      expect(rendered).to match(/function format/)
    end
  end

  context 'with checkboxes. page_header, new_button, directions, filters, row_actions, ect set to false' do
    before :each do
      render partial: "shared/data_table.html.erb", locals: {
        page_header: "",
        new_button: "",
        directions: "",
        processing_text: "",
        custom_handlers: [],
        sibling_pages: [],
    	  filters: [
      		["all", "", true, []],
      		["some", "", true, [
      			["COBRA", "url", "request_type"],
      			["Termed", "url", "request_type"],
      			["Corn", "url", "request_type"]
      		]],
      		["the best ones", "", false, []],
          ["Dad", "", true, [
            ["ZZZ", "url", "request_type"],
      			["Apples", "url", "request_type"],
      			["Corn", "url", "request_type"]
            ]
          ]
      	],
      	bulk_actions: [
      		["Send Secure Message", "", true],
      		["Delete", "", false]
      	],
      	row_functions: false,
      	row_actions: [
      		["asterisk", "url", "request_type", "tooltip"],
      		["bomb", "url", "request_type", "tooltip"],
      		["asterisk", "url", "request_type", "tooltip"],
      		["bomb", "url", "request_type", "tooltip"],
          ["caret-down", "url", "request_type", "View Details"]
      	],
      	buttons_below_table: [
      		['Export CSV', 'url', 'request_type'],
      		['Print', 'url', 'request_type']
      	],
        child_rows: [false, "datatables/child_row"],
        responsive: false,
      	checkboxes: false,
      	pagination: false,
      	ordering: false,
        destroy: true,
      	info: false,
      	table_id: "verification-dataTable",
      	data_url: verifications_index_datatable_exchanges_hbx_profiles_path(:format => :json),
        columns:  [
          ["HBX ID", "hbx_id", "", [false, ""]],
          ["First name", "first_name", "", [false, ""]],
          ["Last name", "last_name", "", [false, ""]],
          ["Documents", "documents", "", [false, ""]],
          ["Due date", "due_date", "", [false, ""]],
      	  ["Status", "review_status", "", [false, ""]],
      	  ["Review", "review", "", [false, ""]],
      	  ["FedHub", "fed_hub", "", [false, ""]]
      	]
      }
    end

    it "should not display the page header" do
      expect(rendered).not_to have_selector('h1.darkblue')
    end

    it "should not display the page header" do
      expect(rendered).not_to have_selector('.btn', text: /Add Datatable/i)
    end

    it "should not include some js functions" do
      expect(rendered).not_to match(/addSelectAll/)
      expect(rendered).not_to match(/makeResponsiveTable/)
      expect(rendered).not_to match(/addBulkActions/)
      expect(rendered).not_to match(/showPagination/)
    end

  end

end
