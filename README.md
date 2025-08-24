<!-- TOC --><a name="taskchamp"></a>

# Taskchamp

![image](https://github.com/user-attachments/assets/9520b546-c709-4a62-bda0-e20816985e14)

Use [Taskwarrior](https://taskwarrior.org/), a simple command line interface to manage your tasks from you computer, and a beautiful native app to manage them from your phone. Create notes for your tasks with seamless [Obsidian](https://obsidian.md/) integration.

> For contributing to Taskchamp, please read the [CONTRIBUTING.md](CONTRIBUTING.md) file.

<!-- TOC start -->

- [Contributing](<(CONTRIBUTING.md)>)
- [Installation](#installation)
- [Setup with Taskwarrior](#setup-with-taskwarrior)
  - [Setup with Taskchampion Sync Server](#setup-with-taskchampion-sync-server)
  - [Setup with AWS](#setup-with-aws)
  - [Setup with GCP](#setup-with-gcp)
  - [Setup with iCloud Drive](#setup-with-icloud-drive)
- [Obsidian integration](#obsidian-integration)
  - [Interact with Obsidian notes from Taskwarrior](#interact-with-obsidian-notes-from-taskwarrior)

<!-- TOC end -->

<!-- TOC --><a name="installation"></a>

## Installation

To install Taskchamp, download the latest [release from the App Store](https://apps.apple.com/us/app/taskchamp-tasks-for-devs/id6633442700).

Taskchamp can work as a standalone iOS app, but it's recommended to use it with Taskwarrior. To install Taskwarrior, follow the instructions [here](https://taskwarrior.org/download/).

> Taskchamp is only compatible with Taskwarrior 3.0.0 or later.

<!-- TOC --><a name="setup-with-taskwarrior"></a>

## Setup with Taskwarrior

There are currently thrww ways to setup Taskchamp to work with Taskwarrior: using a Taskchampion Sync Server, using AWS, using GCP, or using iCloud Drive.

> [!IMPORTANT]
> You only need to setup one of these methods, not all of them.

The documentation for how sync works in Taskwarrior can be found [here](https://taskwarrior.org/docs/sync/).

<!-- TOC --><a name="setup-with-taskchampion-sync-server"></a>

### Setup with Taskchampion Sync Server

> Remote Sync works by connecting to a remote taskchampion-sync-server that will handle the synchronization of your tasks across devices.

1. Setup a Taskchampion Sync Server by following the instructions [here](https://gothenburgbitfactory.org/taskchampion-sync-server/introduction.html).

2. Connect to the server from your computer by following the instructions [here](https://man.archlinux.org/man/extra/task/task-sync.5.en#Sync_Server).

3. Open the Taskchamp app on your phone and select `Taskchampion Sync Server` as your sync service.

4. Enter the URL of your sync server, your client id and encryption secret.

5. You will be able to trigger the sync from your computer by executing: `task sync`.

- Read more about Taskwarrior sync [here](https://taskwarrior.org/docs/commands/synchronize/).

6. Run this command whenever you want to sync your tasks. You can also create a cron job to run run it every few minutes.

7. Your tasks should now be synced between your computer and your phone. You can add tasks from the command line using Taskwarrior, `task sync`, and they will appear on Taskchamp.

<!-- TOC --><a name="setup-with-aws"></a>

### Setup with AWS

> AWS Sync works by connecting to an S3 bucket that will handle the synchronization of your tasks across devices.

1. Setup an S3 bucket that is compatible with taskwarrior sync by following the instructions [here](https://man.archlinux.org/man/extra/task/task-sync.5.en#Amazon_Web_Services).

2. Open the Taskchamp app on your phone and select `Amazon Web Services` as your sync service.

3. Enter the bucket name, region, access key id, secret access key and encryption secret.

4. You will be able to trigger the sync from your computer by executing: `task sync`.

- Read more about Taskwarrior sync [here](https://taskwarrior.org/docs/commands/synchronize/).

5. Run this command whenever you want to sync your tasks. You can also create a cron job to run run it every few minutes.

6. Your tasks should now be synced between your computer and your phone. You can add tasks from the command line using Taskwarrior, `task sync`, and they will appear on Taskchamp.

<!-- TOC --><a name="setup-with-gcp"></a>

### Setup with GCP

> GCP Sync works by connecting to a GCP bucket that will handle the synchronization of your tasks across devices.

1. Setup a GCP bucket that is compatible with taskwarrior sync by following the instructions [here](https://man.archlinux.org/man/extra/task/task-sync.5.en#Google_Cloud_Platform).

2. Open the Taskchamp app on your phone and select `Google Cloud Platform` as your sync service.

3. Enter the bucket name, select your GCP credentials JSON file and encryption secret.

4. You will be able to trigger the sync from your computer by executing: `task sync`.

- Read more about Taskwarrior sync [here](https://taskwarrior.org/docs/commands/synchronize/).

5. Run this command whenever you want to sync your tasks. You can also create a cron job to run run it every few minutes.

6. Your tasks should now be synced between your computer and your phone. You can add tasks from the command line using Taskwarrior, `task sync`, and they will appear on Taskchamp.

<!-- TOC --><a name="setup-with-icloud-drive"></a>

### Setup with iCloud Drive

> Taskchamp can also use iCloud Drive to sync tasks between your computer and your phone. This is described on the Taskwarrior docs [here](https://man.archlinux.org/man/extra/task/task-sync.5.en#ALTERNATIVE:_FILE_SHARING_SERVICES).

**This sync method is not as reliable as using a sync server and is not officially supported by taskwarrior, there is a chance that it might lead to DB corruption** , it is an okay alternative if you don't want to set up server (any of the previous methods) and make sure to backup your data in case of corruption.

> [!IMPORTANT]
> The following instructions are specific for macOS.

> [!NOTE]
> **For Linux Users**
> : If you are using Linux, feel free to follow along but you might need to make some modifications.
> Linux users must use the new [iCloud Drive support in rclone](https://github.com/rclone/rclone/pull/7717)

To setup iCloud Drive Sync, follow these steps:

1. Make sure to have an iCloud account signed in on your phone and computer. Also make sure to have iCloud Drive enabled.

> Ensure that you disable "Optimize Mac Storage" in iCloud Drive's settings

2. Open the Taskchamp app on your phone and select `iCloud Sync` as your sync service. This will create a folder in iCloud Drive called `taskchamp`, this is where your tasks database file will live.

> Sometimes it may take some time for the folder to appear on the finder and files app, but you can access it via terminal.

3. After the folder is created, navigate to it from your computer, and copy your `taskchampion.sqlite3` file into `~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp/`. Replace the existing file if there is one.

> [!NOTE]
> You do not need to move the file, just a copy will do. This is just to make sure that the files have a shared starting point.

- If you want to use a new taskwarrior database, you can skip this step.

4. Open the taskwarrior configuration file, usually located at `~/.taskrc`, and add the following line:

```bash
sync.local.server_dir=~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp
```

- This will tell Taskwarrior to use the `taskchamp` folder in iCloud Drive as a sync directory.
- This path might be a bit different depending on your system (Linux), but you can find the correct path by navigating to the `taskchamp` folder in iCloud Drive and copying the path from the finder, or accessing the directory from your terminal. In MacOS this is `Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp`.

5. You will be able to trigger the sync from your computer by executing: `task sync`.

- Read more about Taskwarrior sync [here](https://taskwarrior.org/docs/commands/synchronize/).

6. Run this command whenever you want to sync your tasks. You can also create a cron job to run run it every few minutes.

7. Your tasks should now be synced between your computer and your phone. You can add tasks from the command line using Taskwarrior, `task sync`, and they will appear on Taskchamp.

<!-- TOC --><a name="obsidian-integration"></a>

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

<!-- TOC --><a name="interact-with-obsidian-notes-from-taskwarrior"></a>

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
