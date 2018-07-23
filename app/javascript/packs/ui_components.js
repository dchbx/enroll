import "babel-polyfill";
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("ui_components/controllers", true, /.js$/)
application.load(definitionsFromContext(context))