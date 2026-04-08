# camoufox

面向 OpenClaw 的 Firefox 系隐身浏览 skill，适合普通抓取或标准浏览器自动化不够稳定的目标站点。

## 它能做什么

- 用更隐蔽的 Firefox 引擎访问更难抓的网站
- 抓取受保护页面的标题或正文
- 对受保护或重 JS 页面截图
- 支持代理、Cookies、等待选择器与结构化 JSON 输出

## 安装

```bash
bash scripts/install.sh
```

## 校验

```bash
bash scripts/check.sh
```

## 常用命令

```bash
/root/.openclaw/workspace/.venvs/camoufox/bin/python \
  /root/.openclaw/workspace/skills/camoufox/scripts/visit.py \
  "https://example.com" --mode title --headless --json

/root/.openclaw/workspace/.venvs/camoufox/bin/python \
  /root/.openclaw/workspace/skills/camoufox/scripts/visit.py \
  "https://example.com" --mode full --headless --json
```

## 说明

- 只有在目标站点较难对付时再用 Camoufox，普通页面优先用更轻量的工具。
- `scripts/visit.py` 是这个 skill 的统一入口。
- 如果包或浏览器资源缺失，重新运行 `scripts/install.sh`。
