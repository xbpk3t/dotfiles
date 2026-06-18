#!/usr/bin/env nu
# session-chain.nu — Track Claude Code sessions in a linked chain
#
# Trigger: SessionStart hook
# Maintains $PROJECT_ROOT/.claude/session-trail/chain.jsonl
#
# Each record:
#   sessionId       — UUID from the current session
#   prevSessionId   — UUID of the prior session in the chain (or null)
#   startedAt       — ISO 8601 timestamp of the first entry in the transcript
#   endedAt         — ISO 8601 timestamp of last update (or null on first append)
#   display         — Truncated first user prompt (max 80 chars)
#   transcriptPath  — Full path to the session's JSONL transcript
#
# Idempotent: re-running updates endedAt without duplicating records.

let project_dir = ($env.CLAUDE_PROJECT_DIR? | default (pwd))

# ── Session identity ──────────────────────────────────────────────
mut session_id = ($env.CLAUDE_CODE_SESSION_ID? | default "")
if ($session_id | is-empty) {
  # Fallback: find the most recently modified JSONL in the session dir
  let path_key = ($project_dir | str replace -a "/" "-")
  let session_dir = [$env.HOME ".claude" "projects" $path_key] | path join
  let files = (ls $session_dir | where type == "file" and ($it.name | str ends-with ".jsonl"))
  if ($files | length) == 0 { exit 1 }
  $session_id = ($files | sort-by modified | last | get name | path basename | str replace ".jsonl" "")
}

# ── Snapshot session_id (immutable) so closures can capture it ────
let sid = $session_id

# ── Transcript path ────────────────────────────────────────────────
let path_key = ($project_dir | str replace -a "/" "-")
let transcript_path = [$env.HOME ".claude" "projects" $path_key $"($sid).jsonl"] | path join

# ── Extract display (first user message) ───────────────────────────
let display = (
  try {
    open $transcript_path
    | lines
    | where ($it | str length) > 0
    | each {|line| $line | from json }
    | where type == "user" and (($it.message?.content? | describe) == "string" or ($it.message?.content? | describe) == "string?")
    | first
    | get message.content
    | str trim
    | str replace -r -a "[\n\r\t ]+" " "
    | split chars | first 80 | str join
  } catch {
    $sid
  }
)

# ── Get startedAt from the first timestamped entry ─────────────────
let started_at = (
  try {
    open $transcript_path
    | lines
    | where ($it | str length) > 0
    | each {|line| $line | from json }
    | where ("timestamp" in $it) and ($it.timestamp | is-not-empty)
    | first
    | get timestamp
  } catch {
    date now | format date "%+"
  }
)

let now_iso = (date now | format date "%+")

# ── Maintain chain.jsonl ────────────────────────────────────────────
let chain_dir = [$project_dir ".claude" "session-trail"] | path join
if not ($chain_dir | path exists) { mkdir $chain_dir }
let chain_file = [$chain_dir "chain.jsonl"] | path join

let chain = (
  if ($chain_file | path exists) {
    open $chain_file | lines | where ($it | str length) > 0 | each {|line| $line | from json }
  } else {
    []
  }
)

let existing_idx = ($chain | enumerate | where item.sessionId == $sid | first | get index? | default (-1))

if $existing_idx >= 0 {
  # Idempotent: update endedAt for a record that already exists
  let updated = ($chain | enumerate | each {|entry|
    if $entry.index == $existing_idx {
      $entry.item | merge { endedAt: $now_iso }
    } else {
      $entry.item
    }
  })
  ($updated | each {|r| $r | to json -r} | str join "\n") + "\n" | save -f $chain_file
} else {
  let prev_id = (if ($chain | length) > 0 { $chain | last | get sessionId } else { null })
  let record = {
    sessionId: $sid
    prevSessionId: $prev_id
    startedAt: $started_at
    endedAt: null
    display: $display
    transcriptPath: $transcript_path
  }
  ($record | to json -r) + "\n" | save --append $chain_file
}
