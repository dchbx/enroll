import { Controller } from "stimulus"
import axios from 'axios'

export default class extends Controller {
  static targets = ['metadata']

  initialize() {
    this.metadata = {
      reason:       this.metadataTarget.dataset.qleReason,
      market:       this.metadataTarget.dataset.qleMarket,
      draft:       this.metadataTarget.dataset.qleDraft
    }
    var market = document.getElementById('market_kind').querySelectorAll('input[type=radio]:checked')[0]
    this.disableOrEnable(market)
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