import { FileWithRuntime } from './fileWithRuntime';

export interface FilesWithRunTime {
  files: (FileWithRuntime | undefined)[];
}

export interface FileGroup {
  files: string[];
}

export type SplitConfig = FileGroup[];
