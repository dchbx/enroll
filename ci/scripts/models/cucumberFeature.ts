export interface CucumberFeature {
  uri: string; // file path
  id: string;
  keyword: 'Feature';
  name: string;
  description: string;
  line: number;
  elements: Array<ScenarioElement | BackgroundElement>;
}

export interface BaseElement {
  name: string;
  description: string;
  line: number;
}

export interface BackgroundElement extends BaseElement {
  keyword: 'Background';
  type: 'background';
  before: BaseStep[];
}

export interface ScenarioElement extends BaseElement {
  id: string;
  keyword: 'Scenario';
  type: 'scenario';
  steps: ScenarioStep[];
  after: BaseStep[];
}

export interface ScenarioStep extends BaseStep {
  keyword: string;
  name: string;
  line: number;
  after: BaseStep[];
}

export interface BaseStep {
  match: {
    location: string;
  };
  result: {
    status: string;
    duration: number; // in nanoseconds
  };
}
