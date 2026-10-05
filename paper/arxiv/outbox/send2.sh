#!/bin/zsh
# usage: send2.sh <draft.txt> <attachment1.pdf> <attachment2.pdf>
set -e
F="$1"; A1="$2"; A2="$3"
TO=$(sed -n '1s/^To: //p' "$F"); SUBJ=$(sed -n '2s/^Subject: //p' "$F"); BODY=$(tail -n +4 "$F")
osascript - "$TO" "$SUBJ" "$BODY" "$A1" "$A2" <<'APPLESCRIPT'
on run argv
  set theTo to item 1 of argv
  set theSubject to item 2 of argv
  set theBody to item 3 of argv
  set att1 to POSIX file (item 4 of argv)
  set att2 to POSIX file (item 5 of argv)
  tell application "Mail"
    set msg to make new outgoing message with properties {sender:"Wonmo (John) Seong <john@orchestrsim.com>", subject:theSubject, content:theBody & return & return, visible:false}
    tell msg
      make new to recipient at end of to recipients with properties {address:theTo}
      make new attachment with properties {file name:att1} at after the last paragraph
      make new attachment with properties {file name:att2} at after the last paragraph
    end tell
    delay 2
    send msg
  end tell
  return "sent to " & theTo
end run
APPLESCRIPT
