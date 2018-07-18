import "babel-polyfill";
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("benefit_sponsors/controllers", true, /.js$/)
application.load(definitionsFromContext(context))
