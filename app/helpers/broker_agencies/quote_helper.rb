module BrokerAgencies::QuoteHelper
	def draft_quote_header(state,quote_name)
		if state == "draft"
			content_tag(:h3, "Review: Publish your #{quote_name}" )+
			content_tag(:span, "Please review the information below before publishing your quote. Once the quote is published, no information can be changed.") 
		end
	end
  def display_dental_plan_option_kind(bg)
    kind = bg.dental_plan_option_kind
    if kind == 'single_carrier'
      'Single Carrier'
    else
      'Custom'
    end
  end
end