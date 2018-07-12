import { InitGroupSelection } from "../legacy/group_selection.js";
import * as legacyBenefitApplications from "../legacy/benefit_application.js";
InitGroupSelection();
window.calculateEmployerContributions = legacyBenefitApplications.calculateEmployerContributions;
window.calculateEmployeeCosts = legacyBenefitApplications.calculateEmployeeCosts;