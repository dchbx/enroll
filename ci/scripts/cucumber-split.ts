const { promises: fs } = require('fs');

import { ScenarioStep, FileWithRuntime, FileGroup } from './models';
import { CucumberFeature } from './models';
import { splitFilesIntoGroups } from './util';

const REPORT_PATH = './ci/cucumber/local-cucumber-report.json';
const SPLIT_CONFIG_PATH = './ci/cucumber-split-config.json';

function calculateStepsRuntime(steps: ScenarioStep[]) {
  return steps.reduce((runTime, step) => {
    return runTime + step.result.duration;
  }, 0);
}

async function createCucumberSplitConfig() {
  const [manualGroupCount] = process.argv.slice(2);

  if (manualGroupCount === undefined) {
    console.error('Please provide the required cli arguments.');
    process.exit(1);
  }

  // Parse cucumber report
  const cucumberReport = await fs.readFile(REPORT_PATH, 'utf-8');
  const report: CucumberFeature[] = JSON.parse(cucumberReport);

  // Generate list of slow files
  const arrayOfSlowFiles: FileWithRuntime[] = report
    .map((feature: CucumberFeature) => {
      // totalRunTime is in nanoseconds
      const totalRunTime = feature.elements.reduce((totalTime, element) => {
        const stepRunTime = calculateStepsRuntime(element.steps);

        return totalTime + stepRunTime;
      }, 0);

      const runtimeInfo: FileWithRuntime = {
        filePath: feature.uri,
        runTime: totalRunTime / 1_000_000,
      };

      return runtimeInfo;
    })
    .sort((a, b) => (a.runTime < b.runTime ? -1 : 1));

  const splitConfig: FileGroup[] = splitFilesIntoGroups(
    arrayOfSlowFiles,
    +manualGroupCount
  );

  await fs.writeFile(SPLIT_CONFIG_PATH, JSON.stringify(splitConfig));
}

createCucumberSplitConfig();
