import React, { useEffect, useState } from 'react';
import { Action, ActionPanel, List, showToast, Toast, Icon } from '@vicinae/api';
import { execSync } from 'child_process';

interface Repository {
  Doc: string;
  Des: string;
  URL: string;
  Tag: string;
  Type: string;
  MainRepo: string;
  SubRepos: string[] | null;
  ReplacedRepos: string[] | null;
  RelatedRepos: string[] | null;
  Cmd: string[] | null;
  IsSubRepo: boolean;
  IsReplacedRepo: boolean;
  IsRelatedRepo: boolean;
  Score: number;
}

interface GhProps {
  arguments: {
    query?: string;
  };
}

// Get the asset path relative to the extension root
// Vicinae/Raycast expects just the filename from the assets folder
const getAssetPath = (filename: string): string => {
  return `gh/${filename}`;
};

// Component to show repository actions
function RepoActions({ repo, onBack }: { repo: Repository; onBack: () => void }) {
  const repoName = repo.URL.split('/').pop() || repo.URL;
  const docsURL = `https://docs.lucc.dev/${repoName}`;

  const actions = [
    { title: 'Open Repository', url: repo.URL, icon: Icon.Globe },
    { title: 'Open in Docs', url: docsURL, icon: Icon.Book },
    ...(repo.Doc ? [{ title: 'Open Documentation', url: repo.Doc, icon: Icon.Document }] : []),
  ];

  return (
    <List searchBarPlaceholder="Select action...">
      <List.Item
        title="← Back to repositories"
        icon={Icon.ArrowLeft}
        actions={
          <ActionPanel>
            <Action title="Back" onAction={onBack} />
          </ActionPanel>
        }
      />
      {actions.map((action, index) => (
        <List.Item
          key={index}
          title={action.title}
          subtitle={action.url}
          icon={action.icon}
          actions={
            <ActionPanel>
              <Action.OpenInBrowser title={action.title} url={action.url} />
              <Action.CopyToClipboard
                title="Copy URL"
                content={action.url}
                shortcut={{ modifiers: ['cmd'], key: 'c' }}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}

export default function Command(props: GhProps) {
  const [repos, setRepos] = useState<Repository[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [selectedRepo, setSelectedRepo] = useState<Repository | null>(null);

  useEffect(() => {
    fetchRepos();
  }, []);

  const fetchRepos = () => {
    setIsLoading(true);
    setError('');

    try {
      // Call dgh binary with raw output
      const cmd = 'dgh --output raw';
      const result = execSync(cmd, { encoding: 'utf-8' }).trim();

      const parsedRepos: Repository[] = JSON.parse(result);
      setRepos(parsedRepos);
    } catch (err) {
      setError(`Error fetching repositories: ${err instanceof Error ? err.message : String(err)}`);
      showToast({
        title: 'Error',
        message: error,
        style: Toast.Style.Failure,
      });
    } finally {
      setIsLoading(false);
    }
  };

  const getRepoName = (url: string): string => {
    const parts = url.split('/');
    return parts[parts.length - 1] || url;
  };

  const getFullRepoName = (url: string): string => {
    // Extract author/repo from GitHub URL
    // Example: https://github.com/author/repo -> author/repo
    const match = url.match(/github\.com\/([^\/]+\/[^\/]+)/);
    if (match && match[1]) {
      return match[1];
    }
    // Fallback to just repo name if pattern doesn't match
    return getRepoName(url);
  };

  const getIcon = (repo: Repository): string => {
    // Icon logic based on Type field from dgh backend:
    // The Type field indicates the icon to use based on repo metadata
    // Mapping: a=qs, b=doc, ab=qs+doc, check=default, search=not found

    const iconMap: { [key: string]: string } = {
      'a': getAssetPath('a.svg'),        // Has quickstart
      'b': getAssetPath('b.svg'),        // Has documentation
      'ab': getAssetPath('ab.svg'),      // Has both qs and doc
      'check': getAssetPath('check.svg'), // Default repo
      'tags': getAssetPath('tags.svg'),
      'types': getAssetPath('types.svg'),
      'search': getAssetPath('search.svg'), // Not found/search
    };

    // Use Type field from backend, default to check.svg for repos, search.svg for no match
    if (repo.Type && iconMap[repo.Type]) {
      return iconMap[repo.Type];
    } else if (repo.URL) {
      return getAssetPath('check.svg');
    } else {
      return getAssetPath('search.svg');
    }
  };

  // If a repository is selected, show its actions
  if (selectedRepo) {
    return <RepoActions repo={selectedRepo} onBack={() => setSelectedRepo(null)} />;
  }

  if (error) {
    return (
      <List>
        <List.EmptyView
          title="Error loading repositories"
          description={error}
          icon={Icon.XMarkCircle}
        />
      </List>
    );
  }

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search repositories (author/repo)...">
      {repos.map((repo) => {
        const fullRepoName = getFullRepoName(repo.URL);

        return (
          <List.Item
            key={repo.URL}
            title={fullRepoName}
            subtitle={repo.Des || repo.Tag}
            icon={getIcon(repo)}
            accessories={[
              { text: repo.Tag }
            ]}
            actions={
              <ActionPanel>
                <Action
                  title="View Actions"
                  onAction={() => setSelectedRepo(repo)}
                />
                <Action.OpenInBrowser
                  title="Quick Open Repository"
                  url={repo.URL}
                  shortcut={{ modifiers: ['cmd'], key: 'o' }}
                />
                <Action.CopyToClipboard
                  title="Copy URL"
                  content={repo.URL}
                  shortcut={{ modifiers: ['cmd'], key: 'c' }}
                />
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}
