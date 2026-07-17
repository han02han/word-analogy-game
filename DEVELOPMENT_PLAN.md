# 中文语义类比解谜游戏 — 开发计划

## 背景

设计一款 PC 端（Steam 风格）中文文字解谜游戏。核心机制：

> **A B C → A ? C → D**
>
> 发现 A → B 之间的隐藏关系，把同一关系套到 C 上，得到 D

以 `巴黎 − 法国 + 西班牙 = 马德里` 为例：巴黎对法国的关系是「首都」，西班牙的首都是马德里。

### 设计决策总览

| 维度 | 决定 |
|---|---|
| 引擎 | Godot 4.x |
| 平台 | Windows .exe |
| 画风 | Q 版可爱手绘（类似《这是谐音梗》） |
| 体量 | 15-20 关精品题 |
| 输入 | 拼字盘（候选字池含干扰项，拖拽/点击排列） |
| 提示 | 消去干扰项，每关 3 次 |
| 评分 | 纯过关制 |
| 叙事 | 无 |
| 插图 | 每关 2 张（变身前/后），答对时过渡动画切换 |
| 题目来源 | 人机协作脑暴 + 人工筛选 |

---

## 项目结构

```
word-analogy-game/
├── project.godot
├── assets/
│   ├── fonts/
│   │   └── SmileFont.ttf              # Q版风格中文字体
│   ├── illustrations/
│   │   ├── lv01_before.png
│   │   ├── lv01_after.png
│   │   └── ...
│   ├── sounds/
│   │   ├── correct.wav
│   │   ├── wrong.wav
│   │   ├── hint.wav
│   │   ├── transform.wav              # 变身音效
│   │   └── complete.wav
│   └── ui/
│       ├── bg_paper.png               # 纸张/卡片背景
│       ├── tile_normal.png
│       ├── tile_selected.png
│       ├── slot_empty.png
│       └── btn_*.png                  # 各类按钮
├── scenes/
│   ├── title_screen.tscn
│   ├── level_select.tscn
│   ├── level_play.tscn
│   └── settings.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd            # 全局状态管理
│   │   └── save_system.gd             # 进度存取
│   ├── ui/
│   │   ├── title_screen.gd
│   │   ├── level_select.gd
│   │   ├── puzzle_ui.gd               # 谜题核心 UI
│   │   ├── tile.gd                    # 单字拼块
│   │   ├── hint_system.gd             # 提示逻辑
│   │   └── illustration_manager.gd    # 插图加载与动画
│   └── settings.gd
└── data/
    └── levels.json                     # 关卡数据（唯一数据源）
```

---

## 场景设计

### 1. 标题画面 (TitleScreen)

```
┌──────────────────────────────────┐
│          🎮 游戏标题             │
│                                  │
│        [ 开始游戏 ]              │
│        [ 继续游戏 ]  ← 有存档时  │
│        [ 设  置   ]              │
│        [ 退  出   ]              │
│                                  │
│        🎨 背景插画               │
└──────────────────────────────────┘
```

### 2. 关卡选择 (LevelSelect)

```
┌──────────────────────────────────┐
│   ← 返回   第 1 页               │
│                                  │
│   [1] [2] [3] [4] [5] [6] [7]   │
│    ✅  ✅  ✅  🔒  🔒  🔒  🔒   │
│                                  │
│   当前选中：第 3 关              │
│          [ 开始 ]               │
└──────────────────────────────────┘
```

- 已通关显示 ✅，当前可玩高亮，未解锁显示 🔒
- 线性解锁，不支持跳关

### 3. 游戏主界面 (LevelPlay)

```
┌──────────────────────────────────┐
│  ← 返回    第 3 关    💡×3      │
│                                  │
│   ┌──────────────────┐          │
│   │                  │          │
│   │   Q版插图(before) │          │
│   │                  │          │
│   └──────────────────┘          │
│                                  │
│   巴黎 − 法国 + 西班牙 = ？     │
│                                  │
│   [巴] [黎] [马] [德] [里]      │
│   [法] [西] [班] [牙]           │
│                                  │
│   答案：[ _ ] [ _ ] [ _ ]       │
│                                  │
│        [ 确认 ]                 │
└──────────────────────────────────┘
```

**交互流程：**
1. 点击候选字 → 填入第一个空槽（或拖拽到槽位）
2. 点击已填入的槽 → 字回到候选池
3. 所有槽填满后 [确认] 按钮高亮
4. 答对 → 插图动画切换（before → after）+ 过关弹窗
5. 答错 → 候选区抖动 + 错误音效，不扣提示

**插图动画：**
- 确认答对 → before 图 fade out / 粒子消散 → after 图 fade in
- 配合「叮！」音效 + 轻微震屏
- 持续约 1.5 秒，可跳过

---

## 关卡数据格式

```json
{
  "levels": [
    {
      "id": 1,
      "puzzle": "巴黎 − 法国 + 西班牙 = ？",
      "answer": ["马", "德", "里"],
      "candidates": ["巴", "黎", "马", "德", "里", "法", "西", "班", "牙"],
      "hint_remove": ["巴", "黎", "法", "西", "班", "牙"],
      "illustration_before": "lv01_paris.png",
      "illustration_after": "lv01_madrid.png"
    }
  ]
}
```

| 字段 | 说明 |
|---|---|
| `puzzle` | 谜题展示文本，直接渲染到屏幕上 |
| `answer` | 正确答案的字序列（用于顺序校验） |
| `candidates` | 候选字池（包含正确答案 + 干扰项，随机打乱展示） |
| `hint_remove` | 提示时按顺序移除的干扰字 |
| `illustration_before/after` | 插图文件名（答对前后） |

---

## 核心脚本概要

### GameManager (autoload)

```
职责：关卡进度、当前关卡、解锁状态
信号：level_completed(level_id)
方法：
  - current_level: int          # 当前正在玩的关卡
  - unlocked_count: int         # 已解锁关卡数
  - complete_level(id)          # 标记过关
  - is_unlocked(id) -> bool
  - reset_progress()            # 重置存档
```

### SaveSystem (autoload)

```
方法：
  - save_progress(data: Dictionary)
  - load_progress() -> Dictionary
  - save_exists() -> bool
存储位置：user://save_data.json
存储内容：{ "unlocked_count": 5, "completed": [1,2,3,4,5] }
```

### PuzzleUI (LevelPlay 场景主控制器)

```
成员：
  - level_data: Dictionary       # 当前关数据
  - answer_slots: Array[Slot]    # 答案槽数组
  - candidate_tiles: Array[Tile] # 候选拼块数组
  - hint_count: int              # 剩余提示次数

信号：
  - level_complete

方法：
  - load_level(id: int)
  - _on_tile_clicked(tile: Tile)
  - _on_slot_clicked(slot: Slot)
  - _on_confirm()
  - _on_hint()
  - _shuffle_candidates()
  - _check_answer() -> bool
```

### Tile（单字拼块）

```
- 显示一个汉字
- 两种状态：在候选池中（可点击） / 已填入槽中（不可选）
- 点击 → 移到第一个空槽 / 或弹出。使用 tween 平滑移动
- 干扰项移除时播放缩小消失动画
```

### HintSystem

```
- 每关 3 次
- 点击提示 → 从 hint_remove 队列中取出 1-2 个干扰字
- 对应 Tile 播放缩小动画后隐藏
- 已消失的 Tile 不可再被选择
```

### IllustrationManager

```
- 管理两张 TextureRect（before / after 叠放）
- 初始状态：before 显示，after 隐藏
- 答对时触发动画：
  1. before 做 fade_out + scale_down (0.3s)
  2. 中间插入粒子/星星效果 (0.4s)
  3. after 做 fade_in + scale_up + bounce (0.5s)
- 加载占位图（开发阶段用纯色代替，插图后期替换）
```

---

## 技术要点

### 拼字盘交互
- Godot Control 节点 + TextureButton/TouchScreenButton
- 拖拽用 `_get_drag_data()` / `_drop_data()` 实现
- 同时支持点击选择（更简单，优先实现）

### 中文输入与本地化
- Godot 内置 UTF-8 支持，直接显示中文
- 字体文件需选择支持中文的 TTF（推荐「站酷快乐体」或「得意黑」等 Q 版开源字体）
- Window 标题设置中文

### 存档
- 使用 `ConfigFile` 或 JSON 文件
- 路径：`OS.get_user_data_dir() + "/save.json"`
- 极小数据量，不需要数据库

### 导出
- Godot → Project → Export → Windows Desktop
- 一键导出 .exe + .pck
- 可配合 rcedit 修改 exe 图标

---

## 开发阶段

### 阶段 1：工程骨架（约 1 天）
- [ ] 创建 Godot 项目
- [ ] 搭建 4 个场景空壳（标题/选关/游戏/设置）
- [ ] 实现场景跳转
- [ ] 创建 GameManager + SaveSystem autoload
- [ ] 关卡 JSON 数据文件 + 加载逻辑

### 阶段 2：核心玩法（约 3 天）
- [ ] PuzzleUI：候选字池渲染 + 随机打乱
- [ ] Tile 组件：点击 → 填充槽位
- [ ] 答案槽：显示已填的字，点击回退
- [ ] 确认/校验逻辑
- [ ] 提示系统：消去干扰项
- [ ] 基础错误/正确反馈（抖动 + 音效占位）

### 阶段 3：插图系统（约 1 天）
- [ ] IllustrationManager：双图层叠放
- [ ] 答对时过渡动画
- [ ] 开发阶段用纯色占位图

### 阶段 4：进度与菜单（约 1 天）
- [ ] 存档/读档
- [ ] 关卡选择界面 + 解锁状态图标
- [ ] 过关弹窗 → 下一关
- [ ] 继续游戏功能

### 阶段 5：润色（约 2-3 天）
- [ ] Q 版 UI 皮肤（按钮、背景、拼块样式）
- [ ] 字体集成
- [ ] 音效集成
- [ ] 标题画面动画
- [ ] 过渡动画（场景切换渐变）

### 阶段 6：内容填充（持续）
- [ ] 下载中文词向量模型（Tencent AI Lab / fastText）
- [ ] 编写 Python 出题脚本（most_similar 穷举 + 批量输出候选）
- [ ] 人工筛选 15-20 道精品题
- [ ] 设计干扰字（每关 5-8 个，含字形相近字、同义字、随机字）
- [ ] 用 AI 工具生成插图（每关 2 张，统一 Q 版 prompt 模板）
- [ ] 填入 levels.json

### 阶段 7：打包发布（约 0.5 天）
- [ ] Windows exe 导出
- [ ] 图标替换
- [ ] 基础测试

---

## 题目设计标准

### 好题三要素
1. **关系不一眼看穿** — 「首都」「货币」太直白，玩家秒懂就没意思
2. **想通后觉得理所当然** — 不能牵强、冷门
3. **答案本身是常识词** — 玩家知道但一时想不到

### 题目模板
```
巴黎 − 法国 + 西班牙 = 马德里    （首都关系）
钥匙 − 门 + 电脑 = 密码          （开锁/验证关系）
翻译 − 语言 + 货币 = 汇率         （转换关系）
做梦 − 睡觉 + 白天 = 白日梦       （状态→行为关系）
口罩 − 病毒 + 阳光 = 防晒霜       （阻挡关系，有范畴跳跃）
王国 − 男人 + 女人 = 女王         （概念替换，锚点字位移）
```

### 词向量辅助出题（核心出题管线）

利用 gensim `most_similar()` 在中文词向量空间中批量发现类比候选：

```
vec(A) − vec(B) + vec(C) ≈ vec(D)
      ↓ most_similar(positive=[A, C], negative=[B])
候选 D₁, D₂, D₃, ...
```

**工具链：**
- 中文词向量：Tencent AI Lab Embedding (800 万词) 或 fastText 中文预训练模型
- Python + gensim 加载模型，写脚本批量查询

**出题流程：**

```
┌─────────────────────────────────────────────────────┐
│ 1. 准备种子维度列表                                  │
│    首都、货币、职业→工具、动物→幼崽、                 │
│    语言→国家、人物→作品、性别变换...                  │
│                                                      │
│ 2. 每个维度下列举实例对                               │
│    首都：[(巴黎,法国), (东京,日本), (伦敦,英国)...]    │
│                                                      │
│ 3. most_similar 穷举交叉组合                          │
│    positive=[巴黎, 日本], negative=[法国]             │
│    → 看看模型输出什么                                 │
│                                                      │
│ 4. 人工筛选                                           │
│    ✓ 答案正确且是常识词                               │
│    ✓ 关系不是一眼能看穿（首都类太直白→降权或剔除）     │
│    ✓ 有「啊哈！」感                                   │
│    ✗ 牵强、冷门、多义词噪音 → 丢弃                    │
│                                                      │
│ 5. 精选入库 → levels.json                            │
└─────────────────────────────────────────────────────┘
```

**脚本示例：**

```python
from gensim.models import KeyedVectors

model = KeyedVectors.load_word2vec_format('cc.zh.300.vec')

def find_analogies(a, b, c, topn=10):
    """找 D: a − b + c ≈ d"""
    return model.most_similar(positive=[a, c], negative=[b], topn=topn)

# 验证已知好题
print(find_analogies('巴黎', '法国', '西班牙'))
# → 应该看到 '马德里' 排名靠前

# 批量发散：固定首都关系，穷举国家组合
capitals = ['巴黎', '东京', '伦敦', '首尔', '柏林', '罗马']
countries = ['法国', '日本', '英国', '韩国', '德国', '意大利']

candidates = []
for cap, co_a in zip(capitals, countries):
    for co_b in countries:
        if co_a == co_b:
            continue
        results = find_analogies(cap, co_a, co_b, topn=3)
        for word, score in results:
            candidates.append({
                'puzzle': f'{cap} − {co_a} + {co_b} = ?',
                'predicted': word,
                'score': score
            })

# 人工筛选 candidates
```

**局限：**
- 需要答案词在词向量词表中（双字词通常覆盖，三字以上可能缺失）
- 模型产出噪音大，筛选工作不可省略
- 抽象概念关系（如「王国→女王」的性别维度）词向量不一定捕获得好

---

## 验证方法

1. 启动 Godot 编辑器，运行项目
2. 从标题 → 选关 → 进入第 1 关
3. 点击候选字填入答案 → 确认 → 验证答对动画
4. 故意答错 → 验证错误反馈
5. 点击提示 → 验证干扰项消除
6. 通关后 → 验证关卡解锁 + 存档
7. 退出 → 重新进入 → 验证「继续游戏」恢复进度
8. 导出 .exe → 在独立 Windows 环境运行验证
