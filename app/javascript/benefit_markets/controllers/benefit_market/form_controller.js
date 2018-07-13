import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "aca_individual", "aca_shop", "select" ]

  initialize() {
  	this.configurationChange({ currentTarget: this.selectTarget })
  }

  configurationChange(event) {
  	Array.prototype.forEach.call(event.currentTarget.options, (option) => {
      this[`${option.value}Target`].classList.add('d-none');
  	})
  	this[`${event.currentTarget.value}Target`].classList.remove('d-none')
  }
}
