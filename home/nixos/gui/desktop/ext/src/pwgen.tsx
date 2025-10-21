import React, { useEffect, useState } from 'react';
import { Action, ActionPanel, Detail, List, showToast, Toast } from '@vicinae/api';
import { execSync } from 'child_process';

interface PwgenProps {
  arguments: {
    website?: string;
  };
}

export default function Command(props: PwgenProps) {
  const [password, setPassword] = useState<string>('');
  const [error, setError] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    generatePassword();
  }, [props.arguments.website]);

  const generatePassword = () => {
    setIsLoading(true);
    setError('');

    try {
      const website = props.arguments.website || '';

      // Try to read secret key from environment variable (set by shell.nix)
      let secretKey = process.env.PWGEN_SECRET || '';

      // Fallback: try to read from /etc/sk/pwgen/sk file
      if (!secretKey) {
        try {
          secretKey = execSync('cat /etc/sk/pwgen/sk 2>/dev/null || echo ""', { encoding: 'utf-8' }).trim();
        } catch (e) {
          // Ignore error, secretKey remains empty
        }
      }

      if (!secretKey) {
        setError('Secret key not found. Please set PWGEN_SECRET environment variable or ensure /etc/sk/pwgen/sk exists');
        setIsLoading(false);
        return;
      }

      // Call pwgen binary with raw output
      const cmd = `pwgen ${website} --secret "${secretKey}" --output raw`;
      const result = execSync(cmd, { encoding: 'utf-8' }).trim();

      setPassword(result);
    } catch (err) {
      setError(`Error generating password: ${err instanceof Error ? err.message : String(err)}`);
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return <Detail markdown="Generating password..." />;
  }

  if (error) {
    return (
      <Detail
        markdown={`# Error\n\n${error}`}
        actions={
          <ActionPanel>
            <Action title="Retry" onAction={generatePassword} />
          </ActionPanel>
        }
      />
    );
  }

  return (
    <Detail
      markdown={`# Generated Password\n\n\`\`\`\n${password}\n\`\`\``}
      metadata={
        <Detail.Metadata>
          <Detail.Metadata.Label title="Website" text={props.arguments.website || 'Default'} />
          <Detail.Metadata.Label title="Password Length" text={password.length.toString()} />
        </Detail.Metadata>
      }
      actions={
        <ActionPanel>
          <Action.CopyToClipboard title="Copy Password" content={password} />
          <Action title="Regenerate" onAction={generatePassword} />
        </ActionPanel>
      }
    />
  );
}
