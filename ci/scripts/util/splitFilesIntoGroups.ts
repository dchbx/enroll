import {
  FileWithRuntime,
  FileGroup,
  SplitConfig,
  FilesWithRunTime,
} from '../models';
import { runtimeDetails } from './numberOfGroups';

export function splitFilesIntoGroups(
  files: FileWithRuntime[],
  groupCount: number
): SplitConfig {
  const { longestTest, totalRuntime, suggestedGroupCount } = runtimeDetails(
    files
  );

  const bucketMaxRunTime = Math.floor(totalRuntime / groupCount);

  console.log({
    longestTest: inMinutes(longestTest),
    totalRuntime: inMinutes(totalRuntime),
    bucketMaxRunTime: inMinutes(bucketMaxRunTime),
    groupCount,
  });

  const groupRunTimes: FilesWithRunTime[] = Array.from(
    { length: groupCount },
    () => ({
      files: [],
    })
  );

  for (const group of groupRunTimes) {
    console.log('Files left to process', files.length);

    while (getGroupRunTime(group) <= bucketMaxRunTime && files.length) {
      // start with file at front of array
      const frontFile = files[0];

      // test whether that file can be added to current group
      const fileIsAddable =
        frontFile.runTime + getGroupRunTime(group) <= bucketMaxRunTime;

      // if that file can be added, add it
      if (fileIsAddable) {
        const file = files.shift();
        group.files.push(file);
      } else {
        const file = files.pop();
        group.files.push(file);
      }
    }
  }

  const groups: FileGroup[] = Array.from({ length: groupCount }, () => ({
    files: [],
  }));

  const a: SplitConfig = groupRunTimes.map((group) => {
    return {
      files: group.files.map((file) => (file as FileWithRuntime).filePath),
    };
  });

  return a;
}

function getGroupRunTime(filesWithRunTime: FilesWithRunTime): number {
  return Math.floor(
    filesWithRunTime.files.reduce((runtime, file) => {
      return file ? runtime + file?.runTime : 0;
    }, 0)
  );
}

function inMinutes(runTime: number): string {
  return `${runTime / 1000 / 60} minutes`;
}
