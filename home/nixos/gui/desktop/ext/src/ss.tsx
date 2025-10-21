import React, { useEffect, useState } from 'react';
import { Action, ActionPanel, List, Icon, Clipboard, showToast, Toast } from '@vicinae/api';
import { execSync } from 'child_process';

interface Snippet {
  name: string;
  val: string;
  group: string;
}

interface SsProps {
  arguments: {
    query?: string;
  };
}

export default function Command(props: SsProps) {
  const [snippets, setSnippets] = useState<Snippet[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    fetchSnippets();
  }, []);

  const fetchSnippets = () => {
    setIsLoading(true);
    setError('');

    try {
      // Call task -g ss:json to get snippets data in JSON format from global taskfile
      const cmd = 'task -g ss:json';
      const rawResult = execSync(cmd, { encoding: 'utf-8' }).trim();

      // Strip the [ss:json] prefix from each line that task adds
      const result = rawResult
        .split('\n')
        .map(line => line.replace(/^\[ss:json\]\s*/, ''))
        .join('\n');

      // Parse the JSON output from task command
      // Expected format: array of {group, sub: [{name, val}]}
      const data = JSON.parse(result);

      // Flatten the data structure
      const flatSnippets: Snippet[] = [];
      data.forEach((groupData: any) => {
        const group = groupData.group;
        groupData.sub.forEach((item: any) => {
          flatSnippets.push({
            name: item.name,
            val: item.val,
            group: group,
          });
        });
      });

      setSnippets(flatSnippets);
    } catch (err) {
      setError(`Error fetching snippets: ${err instanceof Error ? err.message : String(err)}`);
      showToast({
        title: 'Error',
        message: error,
        style: Toast.Style.Failure,
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handlePaste = async (snippet: Snippet) => {
    try {
      await Clipboard.copy(snippet.val);
      await showToast({
        title: 'Copied to Clipboard',
        message: `"${snippet.name}" copied`,
        style: Toast.Style.Success,
      });
    } catch (error) {
      await showToast({
        title: 'Error',
        message: 'Failed to copy snippet',
        style: Toast.Style.Failure,
      });
    }
  };

  if (error) {
    return (
      <List>
        <List.EmptyView
          title="Error loading snippets"
          description={error}
          icon={Icon.XMarkCircle}
        />
      </List>
    );
  }

  // Group snippets by category
  const groups = Array.from(new Set(snippets.map(s => s.group)));

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search snippets...">
      {groups.map((group) => (
        <List.Section key={group} title={group.charAt(0).toUpperCase() + group.slice(1)}>
          {snippets.filter(s => s.group === group).map((snippet) => (
            <List.Item
              key={snippet.name}
              title={snippet.name}
              subtitle={snippet.val.length > 60 ? snippet.val.substring(0, 60) + '...' : snippet.val}
              icon={Icon.Text}
              accessories={[{ text: snippet.group }]}
              actions={
                <ActionPanel>
                  <Action
                    title="Copy to Clipboard"
                    onAction={() => handlePaste(snippet)}
                  />
                  <Action.CopyToClipboard
                    title="Copy Value"
                    content={snippet.val}
                    shortcut={{ modifiers: ['cmd'], key: 'c' }}
                  />
                </ActionPanel>
              }
            />
          ))}
        </List.Section>
      ))}
    </List>
  );
}
