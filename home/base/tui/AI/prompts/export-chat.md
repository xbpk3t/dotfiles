---
description: Export the current chat into a Markdown transcript file at the project root
argument-hint: [TITLE=<english title <=5 words>] [INCLUDE_TOOLS=<0|1>] [SCOPE=<visible|all-possible>]
---
You are exporting the current conversation into a Markdown transcript file.

## Goal
- Create a Markdown file in the project root.
- File name format must be: `<YYYY-MM-DD>-<title>.md`
- `title` must be:
  - pure English
  - lowercase kebab-case
  - no more than 5 words
  - determined from the conversation topic if not provided

## Defaults
- TITLE = auto
- INCLUDE_TOOLS = 0
- SCOPE = visible

## Required behavior
1) Export messages in chronological order.
2) Preserve the original wording as closely as possible.
3) Do not summarize.
4) Do not rewrite for style.
5) Do not compress or omit content unless it is unavailable in the current context.
6) If some content cannot be recovered exactly, add a short note near the top:
   `Note: This export only includes content visible in the current session context.`

## What to include
- Always include:
  - User messages
  - Assistant messages
- By default, exclude:
  - system messages
  - developer messages
  - hidden reasoning
  - tool calls
  - tool outputs
- If `INCLUDE_TOOLS=1`, include tool-related content only when it is explicitly visible and recoverable from the current context.

## Heading format
- Use:
  - `## User [Turn N]`
  - `## Assistant [Turn N]`
- `Turn N` is per message, not per user-assistant pair.
- Count from 1 upward across the full exported transcript.

## Body format
- Put each message body inside:

```text
...
```

- Keep line breaks and formatting where possible.
- Do not add commentary between messages.

## File structure
The file must follow this structure:

```md
# Chat Export

Date: <YYYY-MM-DD>
Scope: <what was included>

---

## User [Turn 1]

```text
...
```

## Assistant [Turn 2]

```text
...
```
```

## Output rules
1) Write the Markdown file to the project root.
2) Use today's date for the filename unless the conversation clearly requires another date.
3) Output only a short confirmation after writing the file:
   - the filename
   - whether tool/system/developer content was excluded
4) Do not print the whole transcript in the chat unless explicitly requested.

Now export the current conversation.
