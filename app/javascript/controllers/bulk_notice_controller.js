import { Controller } from "stimulus";
import StimulusReflex from 'stimulus_reflex';

export default class extends Controller {
  static targets = ['recipientList', 'recipientBadge', 'audienceSelect']

  connect() {
    console.log('connect')
    StimulusReflex.register(this)
  }

  newIdentifierSuccess(element) {
    element.value = '';
  }

  deleteIdentifier(event) {
    let identifierEl = event.currentTarget.closest('span.badge')
    identifierEl.remove()
    event.preventDefault()
    return false
  }

  deleteFile(event) {
    let parentEl = event.currentTarget.closest('div')
    let hiddenInputEl = parentEl.querySelector('input[value="false"]')
    hiddenInputEl.value = true
    parentEl.querySelector('span').remove()
    event.preventDefault()
    parentEl.closest('form').querySelector('input[type="submit"]').setAttribute('value', 'Preview')
    return false
  }
}