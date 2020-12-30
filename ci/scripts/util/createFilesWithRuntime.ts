import { FileWithRuntime, FileWithRuntimeDictionary } from '../models';

export function createFilesWithRuntime(
  filesByRuntime: FileWithRuntimeDictionary
): FileWithRuntime[] {
  return Object.entries(filesByRuntime)
    .map(([key, value]) => {
      const { runTime } = value;
      return {
        filePath: removeLeadingDotSlash(key),
        runTime: runTime * 1000,
      };
    })
    .sort((a, b) => (a.runTime < b.runTime ? 1 : -1));
}

function removeLeadingDotSlash(filePath: string) {
  return filePath.replace(/\.\//, '');
}
