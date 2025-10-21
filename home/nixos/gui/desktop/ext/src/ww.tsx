import React, { useEffect, useState } from 'react';
import { Action, ActionPanel, List, Icon, showToast, Toast } from '@vicinae/api';
import { execSync } from 'child_process';

interface Bookmark {
  alias: string;
  url: string;
}

interface WsProps {
  arguments: {
    query?: string;
  };
}

// Get the asset path relative to the extension root
// Vicinae/Raycast expects just the filename from the assets folder
const getAssetPath = (filename: string): string => {
  return `ws/${filename}`;
};

export default function Command(props: WsProps) {
  const [bookmarks, setBookmarks] = useState<Bookmark[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    fetchBookmarks();
  }, []);

  const fetchBookmarks = () => {
    setIsLoading(true);
    setError('');

    try {
      // Call task command to get bookmarks as JSON
      const cmd = 'task -g ww:json';
      const result = execSync(cmd, { encoding: 'utf-8' }).trim();

      const parsedBookmarks: Bookmark[] = JSON.parse(result);
      setBookmarks(parsedBookmarks);
    } catch (err) {
      setError(`Error fetching bookmarks: ${err instanceof Error ? err.message : String(err)}`);
      showToast({
        title: 'Error',
        message: error,
        style: Toast.Style.Failure,
      });
    } finally {
      setIsLoading(false);
    }
  };
  const getBookmarkIcon = (alias: string): string => {
    // Try to get icon from assets, fallback to generic link icon
    try {
      const iconPath = getAssetPath(`${alias}.png`);
      return iconPath;
    } catch {
      return Icon.Link;
    }
  };

  if (error) {
    return (
      <List>
        <List.EmptyView
          title="Error loading bookmarks"
          description={error}
          icon={Icon.XMarkCircle}
        />
      </List>
    );
  }

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search bookmarks...">
      {bookmarks.map((bookmark) => (
        <List.Item
          key={bookmark.alias}
          title={bookmark.alias}
          subtitle={bookmark.url}
          icon={getBookmarkIcon(bookmark.alias)}
          actions={
            <ActionPanel>
              <Action.OpenInBrowser title="Open in Browser" url={bookmark.url} />
              <Action.CopyToClipboard
                title="Copy URL"
                content={bookmark.url}
                shortcut={{ modifiers: ['cmd'], key: 'c' }}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
