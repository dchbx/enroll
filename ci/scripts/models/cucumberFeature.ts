export interface CucumberFeature {
  uri: string;
  id: string;
  keyword: string;
  name: string;
  description: string;
  line: number;
  elements: FeatureElement[];
}

export interface FeatureElement {
  id: string;
  keyword: string;
  name: string;
  description: string;
  line: number;
  type: string;
  before: any;
  steps: FeatureStep[]; 
}

export interface FeatureStep {
  keyword: string;
  name: string;
  line: number;
  match: {
    location: string;
  };
  result: {
    status: string;
    duration: number // in nanoseconds
  }
}