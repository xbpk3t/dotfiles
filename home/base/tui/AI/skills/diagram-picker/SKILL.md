---
name: diagram-picker
description: Pick diagram type -> tool, then generate source + SVG in .diagram with fixed naming rules
---

# diagram-picker

Use this skill when the user wants you to create a diagram from requirements and you must choose the best diagram type and tool.

## Single source of truth

- Load `references/tools.yaml` for tool capabilities and extensions.
- Load `references/diagram-defaults.yaml` for diagram defaults and reasons.
- Load `references/diagram-aliases.yaml` to normalize diagram type names.
- Load `references/rendering.yaml` for fallback render commands.
- Derive diagram -> tools at runtime by inverting the tool->diagrams map.
- Do not manually maintain diagram -> tools lists.

## Workflow

1) **Parse intent**
   - Infer the most specific diagram type from the request (e.g., sequence for interactions, gantt for schedules, ER for data modeling, mindmap for taxonomy, flowchart for process).
   - Avoid questions unless multiple types are truly indistinguishable; prefer a reasonable default.

2) **Normalize diagram type**
   - If the user provides a diagram type name, normalize it using `diagram-aliases.yaml`.
   - Use only normalized names that exist in `tools.yaml` capabilities.

3) **Pick tool**
   - Build candidate tools by inverting the tool->diagrams map.
   - If multiple candidates fit, pick the `default` from `diagram-defaults.yaml`.
   - If the default is not in the candidate list, ignore it and choose the first candidate by:
     1) Consistency with nearby files or existing style in the project
     2) Tool order in `tools.yaml`
   - If no default exists for the diagram, prefer consistency with nearby files or existing style in the project.

4) **Output location + naming**
   - Output directory: `.diagram` in the working project root.
   - Source filename: `.<tool>.<diagram>.<ext>` where `<ext>` comes from `tools.yaml`.
   - SVG filename suffix: `.<tool>.<diagram>.svg` (same stem).
   - NOTICE: If the image you are converting already has a filename, then directly use that filename. If not, then generate a filename based on the file content. So the final complete filename is `<name>.<tool>.<diagram>.svg`.



5) **Generate source**
   - Keep syntax minimal and readable; avoid unnecessary styling.
   - Default to ASCII unless the domain requires otherwise.

6) **Render SVG (always required)**
   - If a tool-specific skill is available in the current session (name/description matches the tool), call it.
   - Otherwise use the fallback command from `rendering.yaml`.
   - Do not mention missing skills; just proceed with the best available renderer.
   - If a command fails, retry with alternative flags or a simpler diagram rather than skipping SVG.

## Notes

- Do not hardcode external skill names. Use the current session's skill list to discover tool-specific skills.
- If the user specifies a diagram type or tool explicitly, honor it unless it conflicts with `tools.yaml`.
