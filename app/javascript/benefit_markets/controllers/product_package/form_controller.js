import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['healthPackageKind', 'dentalPackageKind', 'defaultPackageKind']

  kindChange(event) {
    document.querySelectorAll('.js-package-kind').forEach(element => {
      element.classList.add('hidden')
    })

    switch (event.currentTarget.value) {
      case 'health':
        this.healthPackageKindTarget.classList.remove('hidden')
        break
      case 'dental':
        this.dentalPackageKindTarget.classList.remove('hidden')
        break
      default:
        this.defaultPackageKindTarget.classList.remove('hidden')
    }
  }
}
