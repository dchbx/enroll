import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["output"]
  
  sendVal() {
    console.log(this.outputTarget.value)
  }
}