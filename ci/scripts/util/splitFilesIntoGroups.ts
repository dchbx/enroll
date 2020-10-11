import {
  FileWithRuntime,
  FileGroup,
  SplitConfig,
  FilesWithRunTime,
} from '../models';
import { groupCount } from './numberOfGroups';

export function splitFilesIntoGroups(files: FileWithRuntime[]): SplitConfig {
  const { longestTest, totalRuntime, suggestedGroupCount } = groupCount(files);
  console.log(
    'Splitting',
    files.length,
    'files into',
    suggestedGroupCount,
    'groups, each being no longer than',
    Math.floor(longestTest),
    'milliseconds long.'
  );

  const groups: FileGroup[] = Array.from(
    { length: suggestedGroupCount },
    () => ({ files: [] })
  );

  const groupRunTimes: FilesWithRunTime[] = Array.from(
    { length: suggestedGroupCount },
    () => ({
      files: [],
    })
  );

  let currentGroup = 0;

  while (files.length) {
    // for (let currentGroup = 0; currentGroup < groups.length; currentGroup++) {
    //   const currentBucketTime = groupRunTimes[currentGroup].runTime;
    //   const file = files.shift();

    //   if (currentBucketTime + file!.runTime <= longestTest) {
    //     groups[currentGroup] = {
    //       files: [...groups[currentGroup].files, file!.filePath],
    //     };
    //     groupRunTimes[currentGroup].runTime += file!.runTime;
    //   } else {
    //     groups[currentGroup + 1] = {
    //       files: [...groups[currentGroup + 1].files, file!.filePath],
    //     };
    //     groupRunTimes[currentGroup + 1].runTime += file!.runTime;
    //   }
    // }
    let file: FileWithRuntime | undefined = files[0];

    for (const group of groupRunTimes) {
      if (file !== undefined) {
        if (file.runTime + getGroupRunTime(group) <= longestTest) {
          group.files.push(file);
          files.shift();
          file = undefined;
        }
      }
    }
  }

  const a: SplitConfig = groupRunTimes.map((group) => {
    return {
      files: group.files.map((file) => (file as FileWithRuntime).filePath),
    };
  });

  // for (const file of files) {
  //   const currentBucketTime = groupRunTimes[currentGroup].runTime;

  //   if (currentBucketTime + file.runTime <= longestTest) {
  //     groups[currentGroup] = {
  //       files: [...groups[currentGroup].files, file.filePath],
  //     };

  //     groupRunTimes[currentGroup].runTime += file.runTime;
  //   } else {
  //     // console.log(file.filePath, 'is too large to go into bucket', bucket);
  //     if (currentGroup < suggestedGroupCount - 1) {
  //       currentGroup += 1;
  //     }
  //     groups[currentGroup] = {
  //       files: [...groups[currentGroup].files, file.filePath],
  //     };
  //     groupRunTimes[currentGroup].runTime += file.runTime;
  //   }
  // }

  // while (files.length > 0) {
  //   const currentBucketTime = groupRunTimes[currentGroup].runTime;
  //   const file: FileWithRuntime | undefined = files.shift();

  //   if (currentBucketTime + file!.runTime <= longestTest) {
  //     groups[currentGroup] = {
  //       files: [...groups[currentGroup].files, file!.filePath],
  //     };
  //   } else {
  //     // Put large file into next bucket
  //     if (currentGroup < suggestedGroupCount - 1) {
  //       currentGroup += 1;
  //       groups[currentGroup] =
  //         groups[currentGroup] === undefined
  //           ? { files: [file!.filePath] }
  //           : { files: [...groups[currentGroup].files, file!.filePath] };
  //       groupRunTimes[currentGroup].runTime += file!.runTime;
  //     }
  //   }
  // }

  // console.log(bucketTimes);
  // console.log(
  //   'Groups created. Total runtime should be no greater than',
  //   longestTest / 1000 / 60,
  //   'minutes long.'
  // );

  return a;
}

function getGroupRunTime(filesWithRunTime: FilesWithRunTime): number {
  return filesWithRunTime.files.reduce((runtime, file) => {
    return runtime + file!.runTime;
  }, 0);
}
