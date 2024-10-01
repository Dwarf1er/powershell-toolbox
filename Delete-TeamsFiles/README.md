# Delete-TeamsFiles

This script when setup as a scheduled task will monitor your local OneDrive folder to delete the "Microsoft Teams Chat Files" folder automatically when you are sharing files in the chat that get copied there as the default behaviour.

## Usage

1. Open Task Scheduler (Win + R, taskschd.msc)
2. Create New Task
3. General Tab:
    - Name the task (e.g. "Delete Microsoft Teams Chat Files")
    - Optionally add a description
    - Choose "Run only when the user is logged on"
4. Triggers Tab:
    - Click "New"
    - From the "Begin the task" dropdown select "At log on"
    - Choose "Any user" or a specific user
5. Actions Tab:
    - Click "New"
    - For "Action" select "Start a program"
    - In the "Program/script" box enter: "powershell"
    - In the "Add arguments (optional)" box enter: "-ExecutionPolicy Bypass -File C:\path\to\Delete-TeamsFiles.ps1"
    - In the "Start in (optional)" box enter the path to the Delete-TeamsFiles.ps1 script on your computer
6. Conditions Tab:
    - Uncheck "Start the task only if the computer is on AC power"
7. Settings Tab:
    - Ensure "Allow task to be run on demand" is checked
    - Optionally set "if the task fails, restart every" to a desired interval
8. Click "OK" to create the task
9. Log off and log back on to trigger the task

Now whenever you share a file in Microsoft Teams chat, the copy made in your OneDrive will be automatically deleted.
