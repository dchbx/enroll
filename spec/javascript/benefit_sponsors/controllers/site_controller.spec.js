//import mountDOM from 'jsdom-mount';
import {Application as StimulusApp} from 'stimulus';
import SiteController from '../../../../app/javascript/benefit_sponsors/controllers/site_controller';

describe('BenefitSponsorsSiteController', () => {
  beforeEach(() => {
    //This would use the commented out import which throws an error so I switched to the built in jsdom

   // mountDOM(`
     // <div data-controller="site">
      //  <div data-target="site.officeLocation" class="js-office-location">
       //   <div id="test" class="row d-none js-non-primary">

         // </div>
       // </div>
       // <a id="button" class="btn btn-sm btn-outline-primary" data-action="click->site#addLocation"
         // Add another location
       // </a>
      //</div>

    //`);


    // This used jsdom as it is built-in as part of Jest
    document.body.innerHTML =
      '<div data-controller=\"site\">' +
       '<div data-target=\"site.officeLocation\" class=\"js-office-location\">' +
       '<div id=\"test\" class=\"row d-none js-non-primary\">' +
       '</div>' +
       '</div>' +
       '<a id=\"button\" class=\"btn btn-sm btn-outline-primary\" data-action=\"click->site#addLocation\"' +
       'Add another location' +
       '</a>' +
      '</div>'

    const stimulusApp = StimulusApp.start();
    stimulusApp.register('siteController', SiteController);
  });

  describe('#addLocation', () => {
    it('unhides the remove button', () => {
      const testDiv = document.getElementById("test");
      const buttonElem = document.getElementById('button');
      const clickEvent = new Event('click');
      buttonElem.dispatchEvent(clickEvent);

      expect(testDiv.getAttribute("class")).toEqual('row js-non-primary');
    });
  });
});