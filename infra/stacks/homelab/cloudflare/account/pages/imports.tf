# Pages projects 的 import 直接跟随 `locals.pages_projects`。
# 这样你在 locals 里停用某个项目后，这里也会自动同步。

import {
  for_each = local.pages_projects

  to = cloudflare_pages_project.projects[each.key]
  id = "${local.account_id}/${each.value.name}"
}
