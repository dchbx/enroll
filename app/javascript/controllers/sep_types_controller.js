import { Controller } from "stimulus"
import axios from 'axios'

export default class extends Controller {
  static targets = ['metadata']

  initialize() {
    this.metadata = {
      ivl_reasons:  JSON.parse(this.metadataTarget.dataset.ivlReasons),
      shop_reasons: JSON.parse(this.metadataTarget.dataset.shopReasons),
      fehb_reasons: JSON.parse(this.metadataTarget.dataset.fehbReasons),
      other_reason: this.metadataTarget.dataset.otherReason,
      ivl_kinds:    JSON.parse(this.metadataTarget.dataset.ivlKinds),
      shop_kinds:   JSON.parse(this.metadataTarget.dataset.shopKinds),
      fehb_kinds:   JSON.parse(this.metadataTarget.dataset.fehbKinds),
      reason:       this.metadataTarget.dataset.qleReason,
      market:       this.metadataTarget.dataset.qleMarket
    }
    var market = document.getElementById('market_kind').querySelectorAll('input[type=radio]:checked')[0]
    var other_reason = this.metadata.other_reason
    this.initializeReasons(market)
    this.initializeEffectiveKinds(market)
    this.disableTerminationkinds(market)
    if (other_reason != ""){
      document.getElementById("other_reason").setAttribute("type", "show");
      document.getElementById("other_reasonHelpBlock").style.display = "block";
      document.querySelector("label[for='other_reason']").style.display = "block";
    }else{
      document.getElementById("other_reason").setAttribute("type", "hidden");
      document.getElementById("other_reasonHelpBlock").style.display = "none";
      document.querySelector("label[for='other_reason']").style.display = "none";
    }
  }

  initializeEffectiveKinds(market){
    var ivl_kinds = this.metadata.ivl_kinds
    var shop_kinds = this.metadata.shop_kinds
    var fehb_kinds = this.metadata.fehb_kinds
    var effective_on_kinds= document.getElementById('effective_on_kinds').querySelectorAll('input[type=checkbox]')
    for (var effective_on_kind of effective_on_kinds){
      effective_on_kind.disabled = false
      effective_on_kind.checked = false
      effective_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = false
    }
    if (market.value == "individual"){
      for (var effective_on_kind of effective_on_kinds){
        if ((ivl_kinds.includes(effective_on_kind.value)) == false){
          effective_on_kind.disabled = true
          effective_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = true
        }
      }
    }
    else if (market.value == "shop"){
      for (var effective_on_kind of effective_on_kinds){
        if ((shop_kinds.includes(effective_on_kind.value)) == false){
          effective_on_kind.disabled = true
          effective_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = true
        }
      }
    }
    else if (market.value == "fehb"){
      for (var effective_on_kind of effective_on_kinds){
        if ((fehb_kinds.includes(effective_on_kind.value)) == false){
          effective_on_kind.disabled = true
          effective_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = true
        }
      }
    }
    if (this.metadataTarget.dataset.terminationKinds != undefined) {
      this.checkSelectedEffectiveKinds()
    }
  };

  disableTerminationkinds(market){
    var termination_on_kinds= document.getElementById('termination_on_kinds').querySelectorAll('input[type=checkbox]')
    for (var termination_on_kind of termination_on_kinds){
      termination_on_kind.disabled = false
      termination_on_kind.checked = false
      termination_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = false
    }
    if (market.value == "individual"){
      for (var termination_on_kind of termination_on_kinds){
        termination_on_kind.disabled = true
        termination_on_kind.checked = false
        termination_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = true
      }
    }else {
      for (var termination_on_kind of termination_on_kinds) {
        termination_on_kind.disabled = false
        termination_on_kind.parentElement.parentElement.parentElement.querySelectorAll('input[type=text]')[0].disabled = false
      }
    }
    if (this.metadataTarget.dataset.effectiveKinds != undefined){
      this.checkSelectedTerminationKinds()
    }
  }

  initializeReasons(market){
    var ivl_reasons = this.metadata.ivl_reasons
    var shop_reasons = this.metadata.shop_reasons
    var fehb_reasons = this.metadata.fehb_reasons
    var id = this.metadata.id

    var items ;
    if (market.value == "individual") {
      items = ivl_reasons
      if (this.metadata.reason != undefined){
        this.setSelectedReason(items, "individual")
      }
    }
    else if (market.value == "shop"){
      items = shop_reasons
      if (this.metadata.reason != undefined){
        this.setSelectedReason(items, "shop")
      }
    }
    else if (market.value == "fehb"){
      items = fehb_reasons
      if (this.metadata.reason != undefined){
        this.setSelectedReason(items, "fehb")
      }
    }
    var str = "<option>" + "Choose..." + "</option>"
    for (var item of items) {
      str += "<option value='" + item[1] + "'>" + item[0] + "</option>"
    }
    if (items.length != 0){
      str += "<option value='other'>"+ "Other" + "</option>"
    }
    document.getElementById("reason").innerHTML = str;
    if (this.metadata.reason != undefined){
      this.checkSelectedReason()
    }
  }

  reasonChange(event) {
    var reason = document.getElementById("reason").value
    if (reason == "other"){
      document.getElementById("other_reason").setAttribute("type", "show");
      document.getElementById("other_reasonHelpBlock").style.display = "block";
      document.querySelector("label[for='other_reason']").style.display = "block";
    }else{
      document.getElementById("other_reason").setAttribute("type", "hidden");
      document.querySelector("label[for='other_reason']").style.display = "none";
      document.getElementById("other_reasonHelpBlock").style.display = "none";
    }
  }

  marketChange(event) {
    var market = document.getElementById('market_kind').querySelectorAll('input[type=radio]:checked')[0]
    this.initializeReasons(market);
    this.initializeEffectiveKinds(market);
    this.disableTerminationkinds(market);
    document.getElementById("other_reason").setAttribute("type", "hidden");
    document.querySelector("label[for='other_reason']").style.display = "none";
    document.getElementById("other_reasonHelpBlock").style.display = "none";
  }

  setSelectedReason(reasons, market){
    var reason = this.metadata.reason
    var sele_market = this.metadata.market
    var other_reason = this.metadata.other_reason
    if (reason == "Choose..." ) return;
    var sele_reason = reason == "other" && other_reason ? "other" : reason
    if (sele_market == market && sele_reason.length != 0 && reasons.flat(1).includes(sele_reason) == false){
        reasons.push([sele_reason.toUpperCase(), sele_reason])
    }
  }

  checkSelectedReason(){
    var reason = this.metadata.reason
    var other_reason = this.metadata.other_reason
    var reasons = document.getElementById("reason").options
    var sele_reason = reason == "other" && other_reason ? "other" : reason
    for (var reason of reasons){
      if (sele_reason == reason.value) {
        reason.selected = true
      }
    }
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

}