module BrokerAgencies::QuoteHelper
	def draft_quote_header(state,quote_name)
		if state == "draft"
			content_tag(:h3, "Review: Publish your #{quote_name}" )+
			content_tag(:span, "Please review the information below before publishing your quote. Once the quote is published, no information can be changed.") 
		end
	end
end