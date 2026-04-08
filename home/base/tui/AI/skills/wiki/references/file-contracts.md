# File Contracts

## plan.md
- Use exactly four top-level sections: `## Todo`, `## Doing`, `## Done`, `## Blocked`.
- Inside each top-level section, prefer `### <task>` subheadings over long flat bullet lists when the section contains real task content.
- `## Done` should normally be organized as task blocks such as `### 初版框架` or `### 第一轮资料扫描`, with supporting bullets or notes nested under the task heading.
- Keep entries research-specific: open questions, pending reads, missing models, blocked design choices, completed task blocks, and attached notes or materials for that task.
- Move an item only when its status clearly changes; do not churn the board every turn.

## research-log.md
- Treat this file as append-only history; each meaningful research turn gets one entry.
- Include structured bullet metadata such as `- Finding:`, `- Source:`, `- Open Question:`, and `- Next Step:` when relevant.
- Reference the related chat slug when a turn depends on an explicitly saved excerpt.

## highlights.md
- Reserve for high-value, durable takeaways that deserve long-term retention for the topic.
- Prefer short, compressed bullets or small sections that can survive many later research turns.
- Update only on clear milestones; this is not a scratchpad.

## sources.md
- Capture validated sources or references cited during the research session.
- Store URLs, book titles, or data sources with a short note on why they matter for the current topic.
- When the user references an existing local article, note, or draft, record the original path and a short relevance note instead of copying it into the topic directory.

## chat/*.md
- Filename pattern: `YYYY-MM-DD-<auto-slug>.md`.
- File-level metadata should stay minimal:
  - `date`
  - `title`
  - `slug`
  - `status`
- Do not auto-write every turn. Append content only when the user explicitly says `$wiki save-turn` or `$wiki st`.
- If no active chat file exists when saving a turn, create one automatically.
- Each saved excerpt should use:
  - `## <auto-title>`
  - `### User`
  - fenced `text` code block
  - `### Agent`
  - fenced `text` code block
- Do not add turn-level metadata such as timestamps, trigger names, or duplicate topic labels.
