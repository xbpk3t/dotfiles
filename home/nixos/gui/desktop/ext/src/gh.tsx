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

export default function Command(props: GhProps) {
  const [repos, setRepos] = useState<Repository[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');

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

  const getDocsURL = (repo: Repository): string => {
    const repoName = getRepoName(repo.URL);
    return `https://docs.lucc.dev/${repoName}`;
  };

  const getIcon = (repo: Repository): any => {
    // Use Icon enum from vicinae API instead of file paths
    // Map repo types to appropriate icons
    const iconMap: { [key: string]: any } = {
      'a': Icon.Star,
      'b': Icon.Book,
      'check': Icon.CheckCircle,
      'tags': Icon.Tag,
      'types': Icon.Code,
      'zzz': Icon.Circle,
    };

    // Default to Circle icon if type not found
    return iconMap[repo.Type] || Icon.Circle;
  };

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
    <List isLoading={isLoading} searchBarPlaceholder="Search repositories...">
      {repos.map((repo) => {
        const repoName = getRepoName(repo.URL);
        const docsURL = getDocsURL(repo);

        return (
          <List.Item
            key={repo.URL}
            title={repoName}
            subtitle={repo.Des || repo.Tag}
            icon={getIcon(repo)}
            accessories={[
              { text: repo.Tag },
              repo.Score > 0 ? { text: `★ ${repo.Score}` } : {},
            ]}
            actions={
              <ActionPanel>
                <Action.OpenInBrowser title="Open Repository" url={repo.URL} />
                <Action.OpenInBrowser
                  title="Open in Docs"
                  url={docsURL}
                  shortcut={{ modifiers: ['cmd'], key: 'enter' }}
                />
                <Action.CopyToClipboard
                  title="Copy URL"
                  content={repo.URL}
                  shortcut={{ modifiers: ['opt'], key: 'enter' }}
                />
                {repo.Doc && (
                  <Action.OpenInBrowser
                    title="Open Documentation"
                    url={repo.Doc}
                    shortcut={{ modifiers: ['shift'], key: 'enter' }}
                  />
                )}
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}
