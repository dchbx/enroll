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
    this.identifierErrorCheck()
  }

  audienceSelectSuccess() {
    this.identifierErrorCheck()
  }

  deleteIdentifier(event) {
    let identifierEl = event.currentTarget.closest('span.badge')
    identifierEl.remove()
    this.displayExpandLink()
    this.identifierErrorCheck()
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
        badges = this.recipientListTarget.querySelectorAll('span.badge'),
        hidden = filter.call(badges, (badge) => { return badge.offsetTop > this.recipientListTarget.offsetHeight });

    if (hidden.length) {
      this.moreRecipientsTarget.classList.remove('d-none')
      this.moreRecipientsTarget.innerText = this.moreRecipientsTarget.innerText.replace(/\d+/, hidden.length)
    } else
        this.moreRecipientsTarget.classList.add('d-none')
  }

  identifierErrorCheck() {
    let filter = Array.prototype.filter,
        badges = this.recipientListTarget.querySelectorAll('span.badge'),
        wrong_type = filter.call(badges, (badge) => { return badge.getAttribute('title') == "Wrong audience type" }),
        not_found = filter.call(badges, (badge) => { return badge.getAttribute('title') == "Not found" })

    let textarea = document.querySelector('#bulk-notice-audience-identifiers')
    if (wrong_type.length && not_found.length)
      textarea.setCustomValidity('Wrong audience type and IDs are not found')
    else if (wrong_type.length)
      textarea.setCustomValidity('Wrong audience type')
    else if (not_found.length)
      textarea.setCustomValidity('IDs not found')
    else
      textarea.setCustomValidity('')
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
    this.displayExpandLink()
    event.preventDefault()
    return false
  }
}