import React from 'react';
import { Action, ActionPanel, List, Icon, Clipboard, showToast, Toast } from '@vicinae/api';

interface Snippet {
  key: string;
  value: string;
  category: string;
}

interface SsProps {
  arguments: {
    query?: string;
  };
}

// Snippets data from Taskfile.snippets.yml
const SNIPPETS: Snippet[] = [
  // Daily snippets
  { key: 'mail', value: 'yyzw@live.com', category: 'daily' },
  { key: 'gmail', value: 'jeffcottlu@gmail.com', category: 'daily' },
  { key: 'MailGk', value: 'kavsalid@gmail.com', category: 'daily' },
  { key: 'mm', value: 'me@lucc.dev', category: 'daily' },
  { key: 'MailNetease', value: '18616287252@163.com', category: 'daily' },
  { key: 'mobile', value: '18616287252', category: 'daily' },
  { key: 'date', value: '{date:short}', category: 'daily' },
  { key: 'pass', value: '159357', category: 'daily' },
  { key: 'time', value: '{time:short}', category: 'daily' },

  // Markdown snippets
  {
    key: 'md-color',
    value: '<font face="黑体" color="green" size="3">{cursor}</font>',
    category: 'markdown'
  },
  {
    key: 'md-summary',
    value: '<details>\n<summary>{cursor}</summary>\n\n\n\n</details>',
    category: 'markdown'
  },

  // Prompts
  {
    key: '3W3H',
    value: 'Why  ->  What  <->  When/where?\nHow to use?\nHow to implement?\nHow to optimize?\n\n帮我结合这个 3W3H 介绍一下',
    category: 'prompts'
  },
  {
    key: 'ImpossibleTriangle',
    value: '好，那还是经典的 快好省不可能三角（性能-质量-成本）\n\n---\n\n按照上面这个不可能三角，重新归类',
    category: 'prompts'
  },
  {
    key: 'Table2YAML',
    value: '我要的不是YAML配置\n\n而是把上面那个table以YAML格式给我 code block',
    category: 'prompts'
  },
  {
    key: 'TableCate',
    value: '能否帮我对以上这些  repo 进行分类\n\n并且就该分类中选择最好、最主流、功能全面的repo',
    category: 'prompts'
  },
  {
    key: 'TableVS',
    value: '给我画个table进行对比，慎重选择对比项，告诉我为什么你做出这个判断\n\n你直接用 ✅、❌ 逐项对比并标记优劣',
    category: 'prompts'
  },
  {
    key: 'TechBreakdown',
    value: '能否用几个标识性的技术来定义一下{cursor}?\n\n比如说 我会说\n\nLSM = AOF + 稀疏索引',
    category: 'prompts'
  },
  {
    key: 'ascii',
    value: '你画个ascii图来说明这个过程吧',
    category: 'prompts'
  },
  {
    key: 'conclusion',
    value: '以下两个问题：\n\n1、能否给上面的整个chat history 做个总结？',
    category: 'prompts'
  },
  {
    key: 'git-msg',
    value: '针对我当前修改代码，生成git commit msg，注意详略得当',
    category: 'prompts'
  },
  {
    key: 'how-to-implement',
    value: '感谢你给我提供的代码\n\n但是我对这个项目的代码一无所知\n\n你觉得我能从这个项目中学到什么？',
    category: 'prompts'
  },
  {
    key: 'kw',
    value: '给我个简单的总结吧，两点：1、为啥tmux这种终端复用工具有用（why） 2、为啥应用zellij而非tmux\n\n两个问题各自提炼3个关键字',
    category: 'prompts'
  },
  {
    key: 'mermaid',
    value: '给我画个ascii图 以及 mermaid图\n\n注意直接给我两个图，后续不需要任何说明',
    category: 'prompts'
  },
  {
    key: 'meta-qs',
    value: '元问题（第一性原理）：这个技术诞生的根本目的是什么？它解决了哪些其他技术无法解决的核心问题？',
    category: 'prompts'
  },
  {
    key: 'qs',
    value: '给我提供一些   相关问题，帮助我了解该领域，注意把相关问题分类，并且从易到难',
    category: 'prompts'
  },
  {
    key: 'repo',
    value: '这个是啥？有啥用？怎么用？',
    category: 'prompts'
  },
  {
    key: 'summary',
    value: '帮我从这些文档中提取几个问题，并回答以及提取回答中的关键字（辅助我记忆）',
    category: 'prompts'
  },
  {
    key: 'validate',
    value: '我上面的说法有问题吗？帮我做个勘误',
    category: 'prompts'
  },
  {
    key: 'yes_or_no',
    value: '以下说法正确吗？',
    category: 'prompts'
  },
];

export default function Command(props: SsProps) {
  const handlePaste = async (snippet: Snippet) => {
    try {
      await Clipboard.copy(snippet.value);
      await showToast({
        title: 'Copied to Clipboard',
        message: `"${snippet.key}" copied`,
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

  // Group snippets by category
  const categories = Array.from(new Set(SNIPPETS.map(s => s.category)));

  return (
    <List searchBarPlaceholder="Search snippets...">
      {categories.map((category) => (
        <List.Section key={category} title={category.charAt(0).toUpperCase() + category.slice(1)}>
          {SNIPPETS.filter(s => s.category === category).map((snippet) => (
            <List.Item
              key={snippet.key}
              title={snippet.key}
              subtitle={snippet.value.length > 60 ? snippet.value.substring(0, 60) + '...' : snippet.value}
              icon={Icon.Text}
              accessories={[{ text: snippet.category }]}
              actions={
                <ActionPanel>
                  <Action
                    title="Copy to Clipboard"
                    onAction={() => handlePaste(snippet)}
                  />
                  <Action.CopyToClipboard
                    title="Copy Value"
                    content={snippet.value}
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
