/** @type {import('stylelint').Config} */
module.exports = {
    // 仅对常见样式文件生效，避免误扫非样式文件
    files: ["**/*.{css,scss,sass}"],
    // SCSS 使用 postcss-scss 解析，避免 CSS parser 对 $变量 报错
    overrides: [
        {
            files: ["**/*.scss", "**/*.sass"],
            customSyntax: "postcss-scss",
        },
    ],
    rules: {
        // 禁止无效 hex 颜色值（invalid hex colors）
        "color-no-invalid-hex": true,
        // 禁止空的代码块（empty blocks）
        "block-no-empty": true,
        // 禁止重复的属性声明（duplicate properties）
        "declaration-block-no-duplicate-properties": true,
        // 禁止未知属性（unknown properties）
        "property-no-unknown": true,
        // 禁止未知类型选择器（unknown type selectors）
        "selector-type-no-unknown": true,
        // 确保 ; 结尾一致（trailing semicolons）
        "declaration-block-trailing-semicolon": "always",
        // 确保字符串使用一致引号（quote style）
        "string-quotes": "double",
        // 控制空行：规则间需要空行（empty lines）
        "rule-empty-line-before": ["always", { "ignore": ["after-comment"] }]
    }
};
