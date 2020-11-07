import { Controller } from "stimulus";
import StimulusReflex from 'stimulus_reflex';
import CableReady from 'cable_ready'
import consumer from '../channels/consumer';

export default class extends Controller {
  connect() {
    StimulusReflex.register(this)
    const controller = this
    consumer.subscriptions.create(
      { channel: 'BulkNoticeProcessingChannel' }, {
        received (data) {
          if (data.cableReady) CableReady.perform(data.operations)
        }
      }
    )
  }
}