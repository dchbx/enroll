import { Controller } from "stimulus"
import axios from 'axios'

export default class extends Controller {
  static targets = ['metadata']

  initialize() {
    this.metadata = {
      reason:       this.metadataTarget.dataset.qleReason,
      qlek_reasons: JSON.parse(this.metadataTarget.dataset.qlekReasons),
      other_reason: this.metadataTarget.dataset.otherReason,
      market:       this.metadataTarget.dataset.qleMarket,
      draft:        this.metadataTarget.dataset.qleDraft
    }
    var market = document.getElementById('market_kind').querySelectorAll('input[type=radio]:checked')[0]
    this.disableOrEnable(market)
    this.initializeReasons()
    this.showorhideOtherReason()
  }

    initializeReasons(){
      var qlek_reasons = this.metadata.qlek_reasons
      var reason_options = document.getElementById("reason")
      for (var qlek_reason of qlek_reasons) {
        if (Array.from(reason_options.options).map(option => option.value).includes(qlek_reason) == false){
          reason_options.options[reason_options.options.length] = new Option(qlek_reason.toLocaleLowerCase().split('_').join(' '), qlek_reason)
        }
      }
      reason_options.options[reason_options.options.length] = new Option("other", "other")
      this.setSelectedReason()
      if (this.metadata.reason != undefined){
        this.checkSelectedReason()
      }
    }

    reasonChange(event) {
      var reason = document.getElementById("reason").value
      this.showorhideOtherReason()
    }

    checkSelectedReason() {
      var reason = this.metadata.reason
      var other_reason = this.metadata.other_reason
      var reasons = document.getElementById("reason").options
      var sele_reason = reason == "other" && other_reason ? "other" : reason
      for (var reason of reasons) {
        if (sele_reason == reason.value) {
          reason.selected = true
        }
      }
    }

    setSelectedReason(){
      var reason = this.metadata.reason
      var other_reason = this.metadata.other_reason
      var reason_options = document.getElementById("reason")
      if (reason == "Choose..." ) return;
      var sele_reason = reason == "other" && other_reason ? "other" : reason
      if (sele_reason.length != 0 && Array.from(reason_options.options).map(option => option.value).includes(sele_reason) == false){
        reason_options.options[reason_options.options.length] = new Option(sele_reason.toLocaleLowerCase().split('_').join(' '), sele_reason)
      }
    }

    showorhideOtherReason(){
      var other_reason = this.metadata.other_reason
      var reason = document.getElementById("reason").value
      if (other_reason != "" && reason == "other" || reason == "other"){
        document.getElementById("other_reason").setAttribute("type", "show");
        document.querySelector("label[for='other_reason']").style.display = "block";
      }else{
        document.getElementById("other_reason").setAttribute("type", "hidden");
        document.querySelector("label[for='other_reason']").style.display = "none";
      }
    }

  disableTerminationkinds(market){
    var termination_on_kinds= document.getElementById('termination_on_kinds').querySelectorAll('input[type=checkbox]')
    for (var termination_on_kind of termination_on_kinds){
      termination_on_kind.disabled = false
      termination_on_kind.checked = false
        //TODO: fix this
      termination_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = false
    }
    if (market.value == "individual"){
      for (var termination_on_kind of termination_on_kinds){
        termination_on_kind.disabled = true
        termination_on_kind.checked = false
          //TODO: fix this
        termination_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = true
      }
    }else {
      for (var termination_on_kind of termination_on_kinds) {
        termination_on_kind.disabled = false
          //TODO: fix this
        termination_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = false
      }
    }
    if (this.metadataTarget.dataset.effectiveKinds != undefined){
      this.checkSelectedTerminationKinds()
    }
  }

  marketChange(event) {
    var market = document.getElementById('market_kind').querySelectorAll('input[type=radio]:checked')[0]
    if (this.metadataTarget.dataset.terminationKinds != undefined) {
      this.checkSelectedEffectiveKinds()
    }
    this.disableTerminationkinds(market);
  }

  checkSelectedTerminationKinds(){
    var termination_on_kinds= document.getElementById('termination_on_kinds').querySelectorAll('input[type=checkbox]')
    var market = document.getElementById('market_kind').querySelectorAll('input[type=radio]:checked')[0]
    var sele_market = this.metadata.market
    var selected_term_on_kinds = JSON.parse(this.metadataTarget.dataset.terminationKinds)
    for (var termination_on_kind of termination_on_kinds){
      if(selected_term_on_kinds.includes(termination_on_kind.value) == true && sele_market == market.value){
        termination_on_kind.checked = true
        termination_on_kind.disabled = false
        termination_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = false
      }
    }
  };

  checkSelectedEffectiveKinds(){
    var effective_on_kinds= document.getElementById('effective_on_kinds').querySelectorAll('input[type=checkbox]')
    var market = document.getElementById('market_kind').querySelectorAll('input[type=radio]:checked')[0]
    var sele_market = this.metadata.market
    var selected_effec_on_kinds = JSON.parse(this.metadataTarget.dataset.effectiveKinds)
    for (var effective_on_kind of effective_on_kinds){
      if(selected_effec_on_kinds.includes(effective_on_kind.value) == true && sele_market == market.value){
        effective_on_kind.checked = true
        effective_on_kind.disabled = false
        effective_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = false
      }
    }
  }

  disableOrEnable(market){
    if(this.metadata.draft == "false") {
      var inputs = document.getElementsByTagName("input");
      for (var i = 0; i < inputs.length; i++) {
        inputs[i].disabled = true;
      }
      var checkbox = document.querySelectorAll('input[type=checkbox]');
      for (var i = 0; i < checkbox.length; i++) {
        checkbox[i].disabled = true;

      }
      var inputs = document.getElementsByTagName("select");
      for (var i = 0; i < inputs.length; i++) {
        inputs[i].disabled = true;
      }
    }else{
      var inputs = document.getElementsByTagName("input");
      for (var i = 0; i < inputs.length; i++) {
        inputs[i].disabled = false;
      }
      var checkbox = document.querySelectorAll('input[type=checkbox]');
      for (var i = 0; i < checkbox.length; i++) {
        checkbox[i].disabled = false;
      }
      if (this.metadataTarget.dataset.terminationKinds != undefined) {
        this.checkSelectedEffectiveKinds()
      }
      this.disableTerminationkinds(market)
    }
  }
}