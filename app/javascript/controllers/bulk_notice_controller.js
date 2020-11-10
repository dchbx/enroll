import { Controller } from "stimulus";
import StimulusReflex from 'stimulus_reflex';

export default class extends Controller {
  static targets = ['recipientList', 'moreRecipients', 'lessRecipients']

  connect() {
    StimulusReflex.register(this)
    window.addEventListener('load', () => this.displayExpandLink())
  }

  newIdentifierSuccess(element) {
    element.value = '';
    this.displayExpandLink()
  }

  deleteIdentifier(event) {
    let identifierEl = event.currentTarget.closest('span.badge')
    identifierEl.remove()
    this.displayExpandLink()
    event.preventDefault()
    return false
  }

  deleteFile(event) {
    let parentEl = event.currentTarget.closest('div')
    let hiddenInputEl = parentEl.querySelector('input[value="false"]')
    hiddenInputEl.value = true
    parentEl.querySelector('span').remove()
    parentEl.closest('form').querySelector('input[type=file]').classList.remove('d-none')
    let submitButton = parentEl.closest('form').querySelector('input[type="submit"]')
    submitButton.setAttribute('value', 'Preview')
    submitButton.dataset.disableWith = 'Preview'
    submitButton.removeAttribute('data-confirm')
    event.preventDefault()
    return false
  }

  displayExpandLink() {
    let filter = Array.prototype.filter,
        result = this.recipientListTarget.querySelectorAll('span.badge'),
        hidden = filter.call(result, (badge) => { return badge.offsetTop > this.recipientListTarget.offsetHeight });

    if (hidden.length) {
      this.moreRecipientsTarget.classList.remove('d-none')
      this.moreRecipientsTarget.innerText = this.moreRecipientsTarget.innerText.replace(/\d+/, hidden.length)
    } else
      this.moreRecipientsTarget.classList.add('d-none')
  }

  expandRecipients(event) {
    this.recipientListTarget.classList.remove('collapsed')
    this.moreRecipientsTarget.classList.add('d-none')
    this.lessRecipientsTarget.classList.remove('d-none')
    event.preventDefault()
    return false
  }

  collapseRecipients(event) {
    this.recipientListTarget.classList.add('collapsed')
    this.moreRecipientsTarget.classList.remove('d-none')
    this.lessRecipientsTarget.classList.add('d-none')
    event.preventDefault()
    return false
  }
}