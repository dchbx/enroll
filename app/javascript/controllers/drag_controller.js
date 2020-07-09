import { Controller } from "stimulus"
import Sortable from "sortablejs"
import Rails from 'rails-ujs';

export default class extends Controller {
	connect() {
		this.sortable = Sortable.create(this.element, {
			onEnd: this.end.bind(this)
		})
	}

	end(event) {
		let index = event.item.dataset.index
		let market_kind = event.item.dataset.market_kind
		let data = {}
		var cards = document.querySelectorAll('.card.mb-4')
		data.market_kind = market_kind
		data.sort = [...cards].reduce(function(data, card, index) { return [...data, { id: card.dataset.id, position: index + 1 }] }, [])
		Rails.ajax({
			url: 'sort',
			type: 'PATCH',
			data: JSON.stringify(data),
			dataType: 'application/json',
			success: function(a,b,c) {
				alert(a['message']);
		  },
		  error: function(a,b,c) {
				alert(a['message']);
		  }
		})
	}
}