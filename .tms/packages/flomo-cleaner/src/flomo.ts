export function isFlomoMineUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return (
      parsed.origin === "https://v.flomoapp.com" &&
      parsed.pathname.startsWith("/mine")
    );
  } catch {
    return false;
  }
}

export function buildInjectedCleanerSource(
  mode: "probe" | "run" = "probe",
): string {
  return String.raw`(() => {
    'use strict';

    // flomo 清空脚本：运行在页面原生上下文，避开 Tampermonkey 沙箱事件差异。

    const mountReport = (state, message) => {
      let root = document.querySelector('[data-flomo-cleaner-root]');
      if (!root) {
        root = document.createElement('aside');
        root.dataset.flomoCleanerRoot = 'true';
        root.style.cssText = [
          'position: fixed',
          'left: 16px',
          'top: 16px',
          'z-index: 2147483647',
          'padding: 12px',
          'border-radius: 14px',
          'background: #0f172a',
          'color: #e2e8f0',
          'font: 12px/1.4 ui-monospace, SFMono-Regular, Menlo, monospace',
        ].join(';');
        document.body.append(root);
      }

      let stateNode = root.querySelector('[data-flomo-cleaner-state]');
      if (!stateNode) {
        stateNode = document.createElement('span');
        stateNode.dataset.flomoCleanerState = 'true';
        root.append(stateNode);
      }

      stateNode.textContent = state;
      stateNode.dataset.flomoCleanerState = state;
      root.dataset.flomoCleanerState = state;
      root.dataset.flomoCleanerMessage = message;
      return root;
    };

    const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
    const log = (...args) => console.log('[flomo-cleaner]', ...args);
    const textOf = (node) => node?.textContent?.replace(/\s+/g, ' ').trim() || '';

    const isVisible = (node) => {
      if (!node) return false;
      const rect = node.getBoundingClientRect();
      const style = getComputedStyle(node);
      return rect.width > 0 && rect.height > 0 && style.display !== 'none' && style.visibility !== 'hidden';
    };

    const dispatchClick = (element) => {
      if (!element) return false;
      for (const type of ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click']) {
        element.dispatchEvent(new MouseEvent(type, {
          bubbles: true,
          cancelable: true,
          composed: true,
          view: window,
        }));
      }
      return true;
    };

    const dispatchHover = (element) => {
      if (!element) return false;
      for (const type of ['pointerenter', 'mouseenter', 'mouseover', 'pointermove', 'mousemove']) {
        element.dispatchEvent(new MouseEvent(type, {
          bubbles: true,
          cancelable: true,
          composed: true,
          view: window,
        }));
      }
      return true;
    };

    const clickAtCenter = (element) => {
      if (!element) return false;
      const rect = element.getBoundingClientRect();
      const hit = document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2);
      if (!hit) return false;
      dispatchHover(hit);
      return dispatchClick(hit);
    };

    const findVisibleNode = (selector, matcher = null) => {
      const nodes = Array.from(document.querySelectorAll(selector)).filter(isVisible);
      return matcher ? nodes.find(matcher) || null : nodes[0] || null;
    };

    const inSelectMode = () => Boolean(document.querySelector('.multiSelect, .select-count'));

    const getSelectedCount = () => {
      const match = textOf(document.querySelector('.select-count')).match(/(\d+)/);
      return match ? Number(match[1]) : 0;
    };

    const isSelectModeMenuItem = (node) => {
      const text = textOf(node);
      if (String(node.className || '').includes('breadcrumb-link')) return false;
      return text === '选择笔记'
        || text === '批量选择'
        || text === '批量选择笔记'
        || /^multi-select\s+memos$/i.test(text);
    };

    const openSelectMode = async () => {
      if (inSelectMode()) return;

      const trigger = findVisibleNode('.breadcrumb-dropdown-item.has-menu.all-memos-trigger, .breadcrumb-dropdown-item.has-menu, .breadcrumb-dropdown .menu-trigger');
      if (!trigger) {
        throw new Error('未找到顶部下拉菜单');
      }

      const inner = trigger.querySelector('.breadcrumb-link, svg') || trigger.firstElementChild || trigger;

      for (let attempt = 0; attempt < 4; attempt++) {
        dispatchHover(trigger);
        await sleep(100);
        clickAtCenter(inner);
        dispatchClick(inner);
        dispatchClick(trigger);
        await sleep(400 + attempt * 150);

        const selectEntry = findVisibleNode(
          '.base-menu .menu-item, .menu-item, button, [role="button"], div, span',
          isSelectModeMenuItem,
        );

        if (selectEntry) {
          dispatchClick(selectEntry);
          await sleep(900);
          if (inSelectMode()) return;
        }
      }

      throw new Error('未能进入“选择笔记/Multi-select Memos”模式');
    };

    const selectAllNotes = async () => {
      const memos = document.querySelector('.memos');
      if (!memos) {
        throw new Error('未找到笔记列表容器 .memos');
      }

      let lastMemoCount = -1;
      let stableRounds = 0;

      for (let round = 0; round < 30; round++) {
        const unchecked = Array.from(document.querySelectorAll('.memo'))
          .filter((memo) => !memo.classList.contains('isSelected'))
          .map((memo) => memo.querySelector('.memo-multi-select-header'))
          .filter(Boolean);

        for (const target of unchecked) {
          dispatchClick(target);
          await sleep(50);
        }

        await sleep(250);

        const memoCount = document.querySelectorAll('.memo').length;
        const selectedCount = getSelectedCount();
        log('round=' + round + ' selected=' + selectedCount + ' memoCount=' + memoCount);

        const beforeTop = memos.scrollTop;
        memos.scrollTo({ top: memos.scrollHeight, behavior: 'instant' });
        await sleep(600);

        if (memos.scrollTop === beforeTop) {
          memos.scrollBy({ top: 1200, behavior: 'instant' });
          await sleep(400);
        }

        const afterMemoCount = document.querySelectorAll('.memo').length;
        if (afterMemoCount === lastMemoCount) {
          stableRounds += 1;
        } else {
          stableRounds = 0;
        }
        lastMemoCount = afterMemoCount;

        if (stableRounds >= 3 && document.querySelectorAll('.memo:not(.isSelected)').length === 0) {
          break;
        }
      }

      return {
        selectedCount: getSelectedCount(),
        memoCount: document.querySelectorAll('.memo').length,
        uncheckedCount: document.querySelectorAll('.memo:not(.isSelected)').length,
      };
    };

    const isDeleteText = (node) => /^(删除|delete)$/i.test(textOf(node));

    const clickDelete = async () => {
      const deleteAction = Array.from(document.querySelectorAll('button, div, span'))
        .filter(isDeleteText)
        .filter((node) => !node.closest('.el-message-box'))
        .filter(isVisible)
        .sort((a, b) => b.getBoundingClientRect().top - a.getBoundingClientRect().top)[0];

      if (!deleteAction) {
        throw new Error('未找到底部删除/Delete 按钮');
      }

      dispatchClick(deleteAction);
      await sleep(350);

      const confirmDelete = Array.from(document.querySelectorAll('button'))
        .find((button) => isDeleteText(button) && String(button.className || '').includes('delete-confirm-button'));

      if (!confirmDelete) {
        throw new Error('未找到删除/Delete 确认按钮');
      }

      dispatchClick(confirmDelete);
      await sleep(5000);
    };

    const verifyCleared = async () => {
      for (let i = 0; i < 20; i++) {
        const memoCount = document.querySelectorAll('.memo').length;
        const bodyText = textOf(document.body);
        if (memoCount === 0) return true;
        if (bodyText.includes('暂无内容')) return true;
        await sleep(500);
      }
      return false;
    };

    const main = async () => {
      const mode = ${JSON.stringify(mode)};
      mountReport('booting', 'starting');

      if (!location.href.startsWith('https://v.flomoapp.com/mine')) {
        mountReport('error', 'not flomo mine');
        throw new Error('当前页面不是 flomo mine: ' + location.href);
      }

      if (mode === 'probe') {
        const probeResult = {
          ok: true,
          mode,
          message: 'probe-ready',
          remainingDomMemos: document.querySelectorAll('.memo').length,
          inSelectMode: inSelectMode(),
          hasDeleteAction: Boolean(
            Array.from(document.querySelectorAll('button, div, span'))
              .find((node) => /^(删除|delete)$/i.test(textOf(node)) && !node.closest('.el-message-box')),
          ),
        };

        mountReport('probe-ready', 'probe-ready');
        log(probeResult);
        return probeResult;
      }

      const bodyText = textOf(document.body);
      if (bodyText.includes('暂无内容') || document.querySelectorAll('.memo').length === 0) {
        mountReport('idle', 'empty');
        return {
          ok: true,
          message: '当前列表没有可删除的笔记',
          remainingDomMemos: document.querySelectorAll('.memo').length,
        };
      }

      if (!window.confirm('将清空当前 flomo 列表中的全部笔记，并移入回收站，是否继续？')) {
        mountReport('cancelled', 'user cancelled');
        return { ok: false, message: '用户取消操作' };
      }

      await openSelectMode();
      mountReport('probing', 'select mode');

      const selection = await selectAllNotes();
      if (selection.memoCount > 0 && selection.uncheckedCount > 0) {
        mountReport('error', 'unchecked notes remain');
        throw new Error('仍有未选中的笔记：' + selection.uncheckedCount);
      }

      if (selection.memoCount === 0) {
        mountReport('idle', 'no notes');
        return {
          ok: true,
          message: '当前列表没有可删除的笔记',
          ...selection,
        };
      }

      await clickDelete();
      const cleared = await verifyCleared();
      mountReport(cleared ? 'done' : 'error', cleared ? 'cleared' : 'not cleared');

      const result = {
        ok: cleared,
        selectedCount: selection.selectedCount,
        remainingDomMemos: document.querySelectorAll('.memo').length,
        message: cleared ? '已删除并清空当前笔记列表' : '删除已触发，但未能在预期时间内确认清空',
      };

      log(result);
      return result;
    };

    void main().catch((error) => {
      const message = error instanceof Error ? error.message : String(error);
      mountReport('error', message);
      console.error('[flomo-cleaner]', error);
    });
  })();`;
}
