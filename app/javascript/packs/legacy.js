import "../polyfills/polyfills";
import "isomorphic-fetch";
import { InitGroupSelection } from "../legacy/group_selection.js";
import * as legacyBenefitApplications from "../legacy/benefit_application.js";
import { MetalLevelSelect } from "../legacy/metal_level_select";
InitGroupSelection();
global.calculateEmployerContributions = legacyBenefitApplications.calculateEmployerContributions;
global.calculateEmployeeCosts = legacyBenefitApplications.calculateEmployeeCosts;
global.MetalLevelSelect = MetalLevelSelect;