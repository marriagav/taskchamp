# Taskchamp

![image](https://github.com/user-attachments/assets/9520b546-c709-4a62-bda0-e20816985e14)

Use [Taskwarrior](https://taskwarrior.org/), a simple command line interface to manage your tasks from you computer, and a beautiful native app to manage them from your phone. Create notes for your tasks with seamless [Obsidian](https://obsidian.md/) integration.

> For contributing to Taskchamp, please read the [CONTRIBUTING.md](CONTRIBUTING.md) file.

## Installation

To install Taskchamp, download the latest [release from the App Store](https://apps.apple.com/us/app/taskchamp-tasks-for-devs/id6633442700).

Taskchamp can work as a standalone iOS app, but it's recommended to use it with Taskwarrior. To install Taskwarrior, follow the instructions [here](https://taskwarrior.org/download/).

> Taskchamp is only compatible with Taskwarrior 3.0.0 or later.

> [!CAUTION]
> Latest version of Taskwarrior breaks Taskchamp sync, for the moment please use Taskwarrior 3.1.0 until I fix this issue: https://github.com/marriagav/taskchamp-docs/issues/2

## Setup with Taskwarrior

> Taskchamp uses iCloud Drive to sync tasks between your computer and your phone. This is described on the Taskwarrior docs [here](https://man.archlinux.org/man/extra/task/task-sync.5.en#ALTERNATIVE:_FILE_SHARING_SERVICES).

> [!IMPORTANT]
> The following instructions are specific for macOS.

> [!NOTE] > **For Linux Users**
> : If you are using Linux, feel free to follow along but you might need to make some modifications.
> Linux users must use the new [iCloud Drive support in rclone](https://github.com/rclone/rclone/pull/7717)

To setup Taskchamp with Taskwarrior, follow these steps:

1. Make sure to have an iCloud account signed in on your phone and computer. Also make sure to have iCloud Drive enabled.
   > Ensure that you disable "Optimize Mac Storage" in iCloud Drive's settings
2. Open the Taskchamp app on your phone. This will create a folder in iCloud Drive called `taskchamp`, this is where your tasks database file will live.

> Sometimes it may take some time for the folder to appear on the finder and files app, but you can access it via terminal.

3. Open the taskwarrior configuration file, usually located at `~/.taskrc`, and add the following line:

```bash
data.location=~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/task
```

- This will tell Taskwarrior to use the `taskchamp` folder in iCloud Drive to store the tasks database file.
- This path might be a bit different depending on your system (Linux), but you can find the correct path by navigating to the `taskchamp` folder in iCloud Drive and copying the path from the finder, or accessing the directory from your terminal. In MacOS this is `Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/task`.
- If you want to use an existing taskwarrior database, you can copy your existing `taskchampion.sqlite3` file to the `~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/task
` folder in iCloud Drive, replacing the existing file. You can do the same for your `hooks` folder if you have any hooks you want to use.

4. iCloud syncing has proven to be less reliable when syncing changes from your iPhone to your computer (works flawlessly the other way around). For this, a shell script has been created to sync the database, ensuring tasks edited on your phone are accurately reflected on your computer.

> I recommend running this script whenever you have made changes on your phone that you want to see on your computer.

The script is very simple, essentially all ot does is reads the file a couple of times (which tells iCloud to sync it):

```bash
#!/bin/bash

task_file="<PATH TO DB FILE>/taskchampion.sqlite3"

# Read the file to trigger the sync
echo "Syncing iCloud file: ${task_file}"
cat "${task_file}" > /dev/null

# Wait for sync
sleep 5
cat "${task_file}" > /dev/null

# Wait for sync
sleep 5
cat "${task_file}" > /dev/null
```

> Make sure to set the correct Path to the taskchampion.sqlite3 file

5. Save this script to a file, for example `sync.sh`, and make it executable by running `chmod +x sync.sh`.

6. Run the script whenever you want to sync your tasks. You can also create a cron job to run the script every few minutes. Another option is to create an alias for the script, so you can run it from the command line easily.

7. Your tasks should now be synced between your computer and your phone. You can add tasks from the command line using Taskwarrior, and they will appear on Taskchamp.

## Obsidian integration

Taskchamp is able to create Obsidian notes for your tasks. Learn more about Obsidian [here](https://obsidian.md/). In order to set Taskchamp to work with Obsidian follow the following steps:

1. Download the Obsidian App
2. Create an Obsidian vault
3. Optional: create a sub-directory for your tasks inside your vault. Otherwise, you can use the base directory of the vault to store your task notes.
4. Create a new task using taskchamp
5. Navigate to the newly created task and press on the "Create obsidian note" button on the bottom of the screen.
6. The first time you do this, you will be prompted for the vault name and sub-directory created earlier. You can always modify these from the settings menu in the Taskchamp app.
7. Once you enter the fields, press the Obsidian note button again, this will take your task note in Obsidian.

The way this works is very simple, a new annotation will be created on the task, which contains the title of the task (with some parsing, like removing whitespaces)

> Note: if you delete the task note or modify its title, you will need to manually update the annotation on the task so that Taskchamp is aware that that note not longer exists or it changed name.

### Interact with Obsidian notes from Taskwarrior

If you want to be able to replicate this functionality for Taskwarrior on MacOS, you can use a bash script that I have created:

```bash
#!/bin/zsh

if [[ $1 =~ ^[0-9]+$ ]]; then
  # $1 is a task ID
  task_id=$1
else
  # $1 is a task name
  task_id=$(task -g "$1" | awk 'NR==4 {print $1}')
  echo "Task ID: $task_id"
fi

task=$(task $task_id)

vault_name="<YOUT_VAULT_NAME>"
sub_dir="<SUBDIRECTORY_FOR_YOUR_TASK_NOTES>"

task_note=$(echo "$task" | awk '/task-note:/ {print $4}')

if [ -n "$task_note" ]; then
   open "obsidian://open?vault=$vault_name&file=$sub_dir/$task_note"
   exit 0
fi

description=$(echo "$task" | awk '/^Description/ {print $2}')

if [ -z "$description" ]; then
  echo "Error: Task not found"
  exit 1
fi

file_name="task-$description"

task $task_id annotate "task-note: "$file_name

open "obsidian://new?vault=$vault_name&file=$sub_dir/$file_name"

```

> Important: Update the `<YOUT_VAULT_NAME>` and `<SUBDIRECTORY_FOR_YOUR_TASK_NOTES>` values before using the script.

Save this script to a file, for example `task-note.sh`, and make it executable by running `chmod +x task-note.sh`.
Run the script by passing the task number as a command.
For example: `task-note.sh 4` will create or open the task note for task with Taskwarrior ID 4
