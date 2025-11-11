# Mail Attachment Extractor

AppleScript to automatically extract attachments from grey-flagged emails and organize them by sender.

## Features

- ✅ **Grey Flag Filter**: Only processes emails flagged grey
- ✅ **Attachment Detection**: Skips emails without attachments
- ✅ **Smart Organization**: Creates folders by sender name
- ✅ **Clean Names**: Extracts readable sender names from email addresses
- ✅ **Duplicate Handling**: Adds (1), (2), etc. to avoid overwriting
- ✅ **Error Logging**: Logs to `mail-extractor.log` instead of showing dialogs
- ✅ **Safe Filenames**: Removes illegal characters

## Setup Instructions

### 1. Configure the Script

Open `mail-attachment-extractor.applescript` and set your target folder:

```applescript
property attachmentsPath : "/Users/beatrixwillius/Documents"
```

### 2. Install in Mail

1. Open **Mail.app**
2. Go to **Mail → Settings → Rules** (or **Preferences → Rules**)
3. Click **Add Rule**
4. Configure:
   - **Description**: "Extract Grey Flagged Attachments"
   - **If**: Choose your conditions (e.g., "Every Message" or specific criteria)
   - **Perform the following actions**:
     - Select **Run AppleScript**
     - Choose `mail-attachment-extractor.applescript`

### 3. Test

1. Flag an email grey in Mail (right-click → Flag → Grey)
2. Make sure it has attachments
3. Run your rule manually or wait for it to trigger
4. Check your Documents folder for new sender folders

## How It Works

### Flag Colors in Mail

Grey flag corresponds to **flag index 1**:
- 🔴 Red = 0
- 🩶 Grey = 1  ← **This script**
- 🟠 Orange = 2
- 🟡 Yellow = 3
- 🟢 Green = 4
- 🔵 Blue = 5
- 🟣 Purple = 6

### Folder Structure

```
Documents/
├── John Doe/
│   ├── report.pdf
│   └── data.xlsx
├── jane_smith/
│   ├── presentation.pptx
│   └── notes.txt
└── mail-extractor.log
```

### Sender Name Extraction

The script handles various email formats:

| Email Format | Extracted Folder Name |
|--------------|----------------------|
| `John Doe <john@example.com>` | `John Doe` |
| `"Smith, Jane" <jane@corp.com>` | `Smith Jane` |
| `contact@company.com` | `contact` |
| `<noreply@site.com>` | `noreply` |

## Key Improvements from Original

1. **Fixed Critical Bug**: Changed `exit repeat` to `next repeat` to process all messages
2. **Grey Flag Filter**: Added flag index check
3. **Better Error Handling**: Logs to file instead of blocking with dialogs
4. **Cleaner Sender Names**: Extracts names from email addresses
5. **Organized by Sender Only**: Simpler folder structure
6. **Robust Edge Cases**: Handles missing values gracefully

## Troubleshooting

### Check the log file:
```bash
tail -f ~/Documents/mail-extractor.log
```

### Common Issues

**Folders not being created?**
- Verify the path exists: `ls -l ~/Documents`
- Check Mail rule is active and saved

**Wrong flag color?**
- Grey flag = flag index 1
- Test by flagging email manually before running rule

**Attachments not saving?**
- Check disk space
- Verify Mail has Full Disk Access in System Settings → Privacy & Security

## Customization

### Change target flag color:

```applescript
-- In the script, find this line:
if messageFlag is not 1 then next repeat

-- Change to:
-- Red (0), Orange (2), Yellow (3), Green (4), Blue (5), Purple (6)
```

### Add date-based subfolders:

```applescript
-- After setting destDir, add:
set theDate to date received of theMessage
set dateStr to my formatDate(theDate) -- implement formatDate handler
set destDir to destDir & "/" & dateStr
```

## License

MIT - Use freely, modify as needed.
