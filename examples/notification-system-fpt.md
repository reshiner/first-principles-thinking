# First Principles Analysis: 通知系统添加 Webhook 支持

> **场景还原：** 现有通知系统通过 `NotificationService` 发送邮件和短信，团队需新增 Webhook 投递渠道。
> 这是一个典型的「if-else 膨胀」案例，FPT 分析揭示了从简单修补到结构性改进的完整决策过程。

## 1. 意图（Intent）

**让系统能够通过 Webhook URL 发送通知给外部服务。** 核心能力是「发送通知」，渠道（邮件、短信、Webhook）是可变维度。用户想要的是新增一个渠道，而不是改变通知系统的本质。

## 2. 现有设计批判（Current Design Critique）

现有代码的核心结构如下（示例代码，非真实项目）：

```
class NotificationService:
    def send(self, type: str, recipient: str, message: str):
        if type == "email":
            # connect SMTP, send email
            ...
        elif type == "sms":
            # connect SMS gateway, send text
            ...
        else:
            raise ValueError(f"Unknown type: {type}")
```

**耦合（Coupling）：** 所有投递逻辑硬编码在 `NotificationService.send()` 中。新增渠道必须修改 `send()` 方法本身，这意味着：
- `send()` 方法需要了解每个渠道的配置细节（SMTP 服务器、SMS 网关地址等）
- 测试时需要为每个渠道设置不同的 mock

**内聚（Cohesion）：** 每个渠道的投递逻辑与路由逻辑混在一起。渠道 A 的配置格式、错误处理、重试策略与渠道 B 无关，却被放在同一个方法体里。

**抽象边界违反：** `send()` 的参数 `type: str` 是典型的字符串类型枚举。调用方负责拼对字符串，否则运行时才能发现错误。没有编译期/类型安全检查。

**扩展成本：** 添加 Webhook 需要：
1. 修改 `send()` 方法，增加 `elif type == "webhook"`
2. 在同一个文件中导入 HTTP 请求库
3. 修改测试文件，在已有的 `test_send` 测试类中新增用例

**隐性假设：**
- 通知渠道永远不会超过 5 个（如果数量级增长，当前模式难以维护）
- 所有渠道的语义相同（发送模式、重试行为、超时策略无差异）
- 渠道增加不需要独立生命周期（部署、监控、配置管理）

## 2b. 被挑战的假设（Assumptions Challenged）

| 假设 | 类别 | 挑战 | 裁定 |
|------|------|------|------|
| "通知不会超过 3 种渠道" | 业务 | 根据 PM 路线图，下个季度还有 Slack 和 Push 两个渠道计划中 | ❌ 推翻 |
| "所有渠道错误处理逻辑一致" | 技术 | Webhook 有 HTTP 状态码、超时、签名验证等独特错误类型，与邮件/SMS 的投递失败语义不同 | ❌ 推翻 |
| "渠道配置可以放在同一个配置文件中" | 技术 | Webhook 需要 URL、密钥、签名算法等特有配置项，与邮件服务器配置无交集 | ❌ 推翻 |
| "必须用同一个 send 接口" | 文化 | "一直这么做的"——但如果每个渠道有不同的参数需求（比如 Webhook 需要 headers），统一接口反而不自然 | ❌ 推翻 |

## 3. 理想方案设计（Clean-Sheet Design）

从第一性原理出发：通知系统的本质是「提交通知请求 → 路由到合适的渠道 → 渠道执行投递」。

```
interface Notifier:
    def send(context: NotificationContext) -> Result

struct NotificationContext:
    recipient: str
    message: str
    metadata: dict   # 渠道特有参数（如 headers、retry_policy）

class EmailNotifier(Notifier):
    def send(self, context): ...

class SmsNotifier(Notifier):
    def send(self, context): ...

class WebhookNotifier(Notifier):
    def send(self, context): ...

class NotificationDispatcher:
    def __init__(self, notifiers: dict[str, Notifier]):
        self._notifiers = notifiers

    def send(self, channel: str, context: NotificationContext) -> Result:
        notifier = self._notifiers.get(channel)
        if not notifier:
            raise ChannelNotFoundError(channel)
        return notifier.send(context)

    def register(self, channel: str, notifier: Notifier):
        self._notifiers[channel] = notifier
```

**设计的核心原则：**
- **开闭原则：** `NotificationDispatcher` 对扩展开放（`register()`），对修改关闭
- **单一职责：** 每个 `Notifier` 只关心自己的投递逻辑
- **类型安全：** 渠道名称作为 key 注册，避免字符串魔法；`NotificationContext` 结构化参数
- **生命周期分离：** 每个 `Notifier` 独立测试、独立部署、独立配置

## 4. 差距分析（Gap Analysis）

| 维度 | 当前 | 理想 | 差距 |
|--------|---------|-------|-------|
| 渠道路由 | `if-elif` 链硬编码 | `Dispatcher.register()` 注册制 | 新增渠道不需要修改路由逻辑 |
| 渠道实现 | 集中在 `send()` 方法中 | 每个渠道独立 `Notifier` 类 | 解耦为独立单元，可独立测试 |
| 参数传递 | `(type, recipient, message)` 三个固参 | `NotificationContext` 结构化对象 | 支持渠道特有参数 |
| 扩展方式 | 修改 `send()` + `elif` | 新建 `*Notifier` 类 + `register()` | 零修改现有代码 |
| 错误处理 | 一个 `try/except` 包全部 | 每个渠道独立错误类型 | 细化错误语义 |

## 5. 路径比较（Path Comparison）

### Path A：最小修改

在现有的 `if-elif` 链中追加一个分支：

```python
elif type == "webhook":
    import requests
    resp = requests.post(recipient, json={"text": message})
    resp.raise_for_status()
```

**优点：**
- 改动量极少：1 个文件，5-8 行代码
- 零风险：不需要重构既有代码

**代价：**
- 设计债务累积：Slack 渠道 → 再加一个 `elif`；Push 渠道 → 再加一个
- 随着渠道增多，`send()` 方法中的 `if-elif` 链理解成本线性增长
- 每个渠道的测试依赖共同测试类，测试配置复杂度增加
- Webhook 的独特行为（签名验证、重试策略、超时配置）需要额外参数，当前签名无法承载

### Path B：第一性原理重构

引入 `Notifier` 接口和 `NotificationDispatcher`，将现有渠道逐个迁移：

1. **创建 `Notifier` 协议/抽象类**（1 文件，新增）
2. **创建 `NotificationDispatcher`**（1 文件，新增）
3. **提取 `EmailNotifier`** — 从 `send()` 中提取邮件逻辑（1 文件，新增）
4. **提取 `SmsNotifier`** — 从 `send()` 中提取短信逻辑（1 文件，新增）
5. **重写 `NotificationService.send()`** 为委托给 `Dispatcher`（1 文件，修改）
6. **实现 `WebhookNotifier`**（1 文件，新增）

**优点：**
- 后续新增渠道只需新建 `*Notifier` + 注册，无需修改现有代码
- 每个渠道可独立测试、独立错误处理
- `NotificationContext` 支持渠道特有参数

**代价与风险：**
- 改动量较大：新建 4-5 个文件，修改 1-2 个文件
- 迁移风险：提取过程中可能遗漏边缘情况
- 需要验证现有测试在新架构下仍通过

## 6. 推荐结论（Recommendation）

**推荐：Hybrid — 采用 Strangler Fig 模式，分步安全推进**

### 决策框架应用

| 启发式 | Path A | Path B |
|--------|--------|--------|
| 改动量 | 1 文件 / 8 行 | 5+ 文件 / ~200 行 |
| 风险 | 极低 | 中等（需覆盖率兜底） |
| 设计债务 | 累积（还有 2 个渠道在路上） | 清除 |
| 下次扩展成本 | 继续加 `elif` | 新建文件 + 注册 |
| 可增量实施？ | 不可增量（一次性改完） | ✅ 可以（逐渠道迁移） |

1. **Touch frequency：** PM 已规划 Slack 和 Push 两个新渠道，且通知系统是核心基础设施，会被反复修改 → 倾向于 Refactor
2. **Provably wrong：** 当前设计在「渠道数 > 3」时 provably wrong——`if-elif` 链的可维护性在 N > 5 后急剧下降
3. **Strangler Fig test：** ✅ 可以！不需要一次性重构，逐个渠道迁移：

### 具体实施步骤

```
Step 1: 创建 Notifier 接口 + 提取 EmailNotifier（保留原 send() 不变）
  → verify: 现有测试全部通过

Step 2: 创建 NotificationDispatcher，将 EmailNotifier 注册
  → 修改 send() 优先走 Dispatcher 路由，email 渠道到新路径
  → verify: email 通知正常，测试通过

Step 3: 提取 SmsNotifier，注册到 Dispatcher
  → 修改 send() 将所有已知渠道走 Dispatcher
  → verify: email + sms 通知正常，测试通过

Step 4: 实现 WebhookNotifier，注册到 Dispatcher
  → 新增渠道，不走 if-elif 链
  → verify: 所有渠道正常，新增 Webhook 测试

Step 5: 清理旧的 if-elif 链（可选安全步骤）
  → verify: 回归全部测试
```

每一步都是一个可独立 review 的 PR。如果某一步出现问题，回滚只影响该步，不影响全部。