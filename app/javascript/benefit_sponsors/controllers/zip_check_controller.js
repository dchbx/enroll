import { Controller } from "stimulus"
import axios from 'axios'

export default class extends Controller {
  static targets = ['countySelect']

  initialize() {
    let kind_select = document.getElementById('kindSelect')
    if (kind_select) {
      kind_select.value = "primary";
    }
  }

  zipChange(event) {
    axios({
      method: 'POST',
      url: '/benefit_sponsors/profiles/registrations/counties_for_zip_code',
      data: { zip_code: event.currentTarget.value },
      headers: {
        'X-CSRF-Token': document.querySelector("meta[name=csrf-token]").content
      }
    }).then((response) => {

      if (response.data.length >= 1) {
        this.countySelectTarget.removeAttribute('disabled')
        this.countySelectTarget.options.length = 0;
        event.target.parentElement.classList.remove('was-validated')
        event.target.setCustomValidity("")
        let optionValues = JSON.parse(this.countySelectTarget.dataset.options);

        for (let option of optionValues) {
          if (response.data.includes(option)) {
            let newOption = document.createElement("option")
            newOption.text = option;
            newOption.value = option;
            this.countySelectTarget.add(newOption)
          }
        }

      } else {
        this.countySelectTarget.setAttribute('disabled', true);
        this.countySelectTarget.options.length = 0;
        let newOption = document.createElement("option")
        newOption.text = "Zipcode outside of MA";
        newOption.value = "Zipcode outside of MA";
        this.countySelectTarget.add(newOption)
        event.target.parentElement.classList.add('was-validated')
        event.target.setCustomValidity("Zipcode outside of MA")
      }
      if (this.countySelectTarget.parentElement.className == 'selectric-hide-select') {
        $(this.countySelectTarget).selectric('refresh')
      }
    })
  }
}
