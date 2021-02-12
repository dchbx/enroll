import Rails from 'rails-ujs';
import Turbolinks from 'turbolinks';
import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";
import 'bootstrap';
import 'jquery';
import 'jquery-ui';
import '../css/application.scss';
import '@fortawesome/fontawesome-free';
import '@fortawesome/fontawesome-free/js/solid.js';
import '@fortawesome/fontawesome-free/js/regular.js';
import '@fortawesome/fontawesome-free/js/brands.js';
import '@fortawesome/fontawesome-free/js/fontawesome.js';
import '@fortawesome/fontawesome-free/svgs/regular/copyright.svg';
import '@fortawesome/fontawesome-free/svgs/regular/envelope.svg';
import '@fortawesome/fontawesome-free/svgs/solid/phone.svg';
import '@fortawesome/fontawesome-free/svgs/solid/question.svg';
import 'sweetalert2';


Rails.start()
Turbolinks.start()

const importAll = (r) => r.keys().map(r)
importAll(require.context('../images', false, /\.(png|jpe?g|svg|ico)$/));

const application = Application.start()
const context = require.context("controllers", true, /.js$/)
application.load(definitionsFromContext(context))
