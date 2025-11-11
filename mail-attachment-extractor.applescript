-- Mail Attachment Extractor
-- Extracts attachments from grey-flagged emails and organizes by sender
-- CONFIG: set the target folder as a POSIX path without trailing slash
property attachmentsPath : "/Users/beatrixwillius/Documents"

-- sanity check
if not my dirExists(attachmentsPath) then
	display dialog "Folder not found: " & attachmentsPath
	return
end if

using terms from application "Mail"
	on perform mail action with messages theMessages for rule theRule
		repeat with theMessage in theMessages
			try
				-- Check if message has attachments
				set theAttachments to mail attachments of theMessage
				if (count of theAttachments) = 0 then next repeat -- FIXED: was "exit repeat"

				-- Check if message is flagged grey (flag index 1)
				set messageFlag to flag index of theMessage
				if messageFlag is not 1 then next repeat

				-- Extract and clean sender name
				set theSender to sender of theMessage as text
				if theSender is missing value then set theSender to "unknown"
				set senderName to my extractSenderName(theSender)

				-- Create destination folder by sender name
				set destDir to attachmentsPath & "/" & senderName

				-- Make destination folder idempotently
				do shell script "mkdir -p " & quoted form of destDir

				-- Save each attachment
				repeat with theAttachment in theAttachments
					set originalName to name of theAttachment as text
					if originalName is missing value then set originalName to "attachment"

					set safeName to my sanitize(originalName)
					if safeName = "" then set safeName to "attachment"

					set outPath to destDir & "/" & safeName
					set outPath to my uniquePath(outPath) -- avoid overwrite

					save theAttachment in POSIX file outPath
				end repeat

				-- Log success
				my logMessage("Saved " & (count of theAttachments) & " attachment(s) from " & senderName)

			on error errMsg number errNr
				-- Log errors instead of showing dialogs
				my logMessage("Error processing message: " & errMsg & " (Error " & errNr & ")")
			end try
		end repeat
	end perform mail action with messages
end using terms from


-- UTILITIES

on dirExists(p) -- p = POSIX path string
	try
		do shell script "test -d " & quoted form of p
		return true
	on error
		return false
	end try
end dirExists

on extractSenderName(sender as text)
	-- Email format is usually "Name <email@example.com>" or just "email@example.com"
	set cleanName to sender

	-- Extract name from "Name <email>" format
	if sender contains "<" then
		set cleanName to text 1 thru ((offset of "<" in sender) - 1) of sender
		set cleanName to my trim(cleanName)

		-- Remove quotes around name if present
		if cleanName starts with "\"" and cleanName ends with "\"" then
			if (count of characters of cleanName) > 2 then
				set cleanName to text 2 thru -2 of cleanName
			end if
		end if
	end if

	-- If name is empty or just email, extract username from email
	if cleanName = "" or cleanName contains "@" then
		if sender contains "@" then
			-- Extract username part before @
			set atPos to offset of "@" in sender
			if atPos > 1 then
				set cleanName to text 1 thru (atPos - 1) of sender
				-- Remove <> if present
				if cleanName contains "<" then
					set cleanName to text ((offset of "<" in cleanName) + 1) thru -1 of cleanName
				end if
			end if
		end if
	end if

	set cleanName to my sanitize(cleanName)
	if cleanName = "" then set cleanName to "unknown-sender"

	return cleanName
end extractSenderName

on sanitize(t as text)
	set s to t as text
	-- replace line breaks with spaces
	set s to my replaceText(s, return, " ")
	set s to my replaceText(s, linefeed, " ")

	-- strip characters illegal or annoying in filenames
	set s to my replaceText(s, "\"", "") -- remove double quotes
	set badChars to {":", "/", "\\", "*", "?", "<", ">", "|"}
	repeat with c in badChars
		set s to my replaceText(s, c as text, "_")
	end repeat

	-- collapse repeated spaces
	repeat while s contains "  "
		set s to my replaceText(s, "  ", " ")
	end repeat

	set s to my trim(s)

	-- limit filename length (folder names and filenames)
	if (count characters of s) > 100 then set s to text 1 thru 100 of s
	return s
end sanitize

on replaceText(theText as text, findStr as text, replStr as text)
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to findStr
	set parts to text items of theText
	set AppleScript's text item delimiters to replStr
	set newText to parts as text
	set AppleScript's text item delimiters to oldDelims
	return newText
end replaceText

on trim(s as text)
	set blanks to {" ", tab, return, linefeed}
	if s = "" then return s
	repeat while (s ≠ "") and (blanks contains character 1 of s)
		if (count of characters of s) > 1 then
			set s to (text 2 thru -1 of s)
		else
			set s to ""
			exit repeat
		end if
	end repeat
	if s = "" then return s
	repeat while (blanks contains character -1 of s)
		if (count of characters of s) > 1 then
			set s to (text 1 thru -2 of s)
		else
			set s to ""
			exit repeat
		end if
	end repeat
	return s
end trim

on uniquePath(p as text) -- returns p or p with (n) suffix to avoid collisions
	set sh to "
p=" & quoted form of p & ";
if [ -e \"$p\" ]; then
  dir=$(dirname \"$p\")
  file=$(basename \"$p\")
  name=\"${file%.*}\"
  ext=\"${file##*.}\"
  [ \"$ext\" = \"$file\" ] && ext=\"\"
  i=1
  while :; do
    if [ -z \"$ext\" ]; then candidate=\"$dir/$name ($i)\"; else candidate=\"$dir/$name ($i).$ext\"; fi
    [ ! -e \"$candidate\" ] && echo \"$candidate\" && break
    i=$((i+1))
  done
else
  echo \"$p\"
fi"
	return do shell script sh
end uniquePath

on logMessage(msg as text)
	try
		set logFile to attachmentsPath & "/mail-extractor.log"
		set timestamp to (current date) as text
		set logEntry to timestamp & " - " & msg
		do shell script "echo " & quoted form of logEntry & " >> " & quoted form of logFile
	end try
end logMessage
