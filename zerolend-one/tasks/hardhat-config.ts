import path from 'path';
import fs from 'fs';

export const loadTasks = (taskFolders: string[]): void =>
  taskFolders.forEach((folder) => {
    const tasksPath = path.join(__dirname, '../', folder);
    fs.readdirSync(tasksPath)
      .filter((pth) => pth.includes('.ts') || pth.includes('.js'))
      .forEach((task) => {
        require(`${tasksPath}/${task}`);
      });
  });
