variable "pages_docs_cfp_pwd" {
  description = "docs Pages project 使用的 CFP_PASSWORD。为了避免 secret 落仓库，这里通过 TF_VAR_pages_docs_cfp_pwd 注入。"
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}
