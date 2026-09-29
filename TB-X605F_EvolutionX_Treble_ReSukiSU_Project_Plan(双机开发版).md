# TB-X605F 高版本 Evolution X / Treble GSI / ReSukiSU 项目总计划

> 目标设备：Lenovo Tab M10 TB-X605F，Wi-Fi-only，3GB RAM + 32GB eMMC  
> 当前状态：已经通过 Qualcomm 9008/EDL 刷入 Android 9 ROW 系统，Bootloader 已解锁；此前使用的 ROW 9008/QFIL 工厂包目前不在本地，需要重新下载并保存。  
> 项目目标：把这台老设备做成“能长期使用、同时值得折腾”的高版本 Android 实验平台，主要用途是 PC 副屏，其次是文档阅读和视频播放；系统优先 Evolution X Google Apps 版，不使用 vanilla/纯净版，不为了镜像体积裁剪 GApps/EvoX 核心功能，空间不足允许调整 GPT、扩大物理 system 分区。后续只采用 ReSukiSU 作为内核 Root 路线。

---

## 1. 总体技术路线

不要一开始做完整的 device-specific Lineage/Evolution X ROM。优先采用下面的“杂交”结构：

```text
Evolution X Android 16/17 userspace
            │
            ├─ TrebleDroid / PHH compatibility
            ├─ X605F 专属 patches / overlays / props
            ├─ System-as-Root 兼容
            └─ Google Apps / Pixel 体验组件
                         │
                         ▼
              Lenovo Android 9 vendor
                         │
              proprietary HAL / blobs
                         │
                         ▼
             Lenovo 3.18.120 kernel
                         │
                  后续自编 kernel
                         │
                    ReSukiSU
```

第一阶段先用现成 Evolution X Android 16 QPR2 Treble GSI 验证硬件和 vendor 兼容性；稳定后再建立自己的 EvoX Treble 源码构建树。Android 16 是 bring-up 基线，最终目标可以推进到 Android 17。Evolution X 当前官方开发重心已经转向 Android 17 `cnb`，Android 16 `bka` 仍处于维护状态，因此不要把项目架构写死在 A16。

---

## 2. Codex 的执行权限和人机分工

本项目的软件侧操作全部交给 Codex 执行。用户已经授权 Codex 在这台指定 TB-X605F 上进行下载、备份、ADB/Fastboot/EDL 操作、镜像处理、分区分析、刷写、日志抓取、源码同步、编译、打包、修改 GPT、恢复等操作。

### Codex 应自行完成

- 下载和验证需要的工具、源码、ROM、工厂包。
- 自动识别 ADB / Fastboot / Recovery / Qualcomm 9008 状态。
- 获取和记录设备属性、分区表、GPT、文件系统、boot image 信息。
- 备份和校验所有需要保存的分区。
- 准备并验证 9008/QFIL 救砖环境。
- 下载、解压、校验 EvoX GSI。
- 判断所需 GSI 架构和 SAR/Treble 条件。
- 根据真实 GPT 计算并执行 system 分区扩容。
- 处理 ext4 resize、SAR、PHH/Treble compatibility patch。
- 刷写 GSI、恢复 vendor/boot 等必要组件。
- 抓取 logcat、dmesg、pstore 等日志并自行分析。
- 编译自己的 EvoX GSI。
- 编译 clean Lenovo kernel，再集成 ReSukiSU。
- 自动维护 Git 仓库、commit、patchset、测试记录和回滚产物。

### 用户只负责必须由真人完成的物理操作

例如：

- 插拔 USB 线。
- 长按/组合按键。
- 手工进入 Bootloader / Recovery / Qualcomm 9008 模式。
- 必要时确认电脑端驱动设备是否重新枚举。
- 观察屏幕：Lenovo Logo、boot animation、黑屏、闪屏、触摸是否工作等，并把观察结果告诉 Codex。

**不要让用户复制粘贴命令、手工改文件或人工计算扇区。**  
只要可以由当前电脑上的终端和工具完成，就由 Codex直接执行。只有需要真实物理交互时才暂停并明确告诉用户“现在按什么键/拔插什么”。

对于破坏性操作，不需要反复询问用户确认，但必须在执行前由 Codex 自己完成必要的备份、设备身份核验和恢复路径检查。若无法确认当前连接的是目标 TB-X605F，必须停止，以避免操作错误设备。

---

## 3. 开工前：重新准备 Android 9 ROW 9008/QFIL 工厂包

虽然设备以前已经通过 9008 刷过 ROW Android 9，但当前本地没有保存那份工厂包，因此开工后的第一项工作是重新找到并下载一份**明确对应 TB-X605F Wi-Fi 版**的 Android 9 ROW QFIL/9008 包。

Codex 应：

1. 优先查找 Lenovo 官方/历史支持来源，其次使用可信的社区镜像。
2. 核对型号必须是 `TB-X605F`，不要拿 `TB-X605L` LTE 包直接当恢复包。
3. 保存原始下载文件，不要只保存解压后的工作目录。
4. 计算 SHA-256。
5. 解压后检查 Qualcomm firehose programmer、rawprogram XML、patch XML、镜像文件是否完整。
6. 记录固件版本、来源 URL、下载日期和哈希。
7. 放入项目的 `recovery-assets/stock-row/` 或独立的不可修改目录。

这个工厂包是“系统层面救砖”的基础，但它不能替代本机设备特定数据的备份。

---

## 4. 设备级备份：重点是 GPT + 本机唯一/校准数据

本机为 Wi-Fi-only，因此不需要把 IMEI/QCN/蜂窝基带恢复当作核心任务，但仍然要保留所有实际存在的设备特定小分区。

在第一次修改 GPT 或刷高版本 GSI 之前，Codex 应自动完成：

### 4.1 GPT 备份

必须保存：

- Primary GPT。
- Backup GPT。
- 完整分区列表。
- 每个分区的：
  - name
  - start LBA
  - end LBA
  - size
  - type GUID
  - unique GUID
  - filesystem（能识别时）
- `/dev/block/by-name` 对应关系。

建议同时生成：

- 人类可读表格。
- `sgdisk`/EDL 可恢复格式。
- rawprogram XML（工具支持时）。

### 4.2 设备特定小分区

至少备份：

- `persist`

以及 GPT 中实际存在的：

- `fsg`
- `fsc`
- `modemst1`
- `modemst2`
- `sec`
- `devinfo`
- `misc`
- `frp`
- 其他体积较小且用途不明的持久化/NV/校准分区

不要因为本机是 Wi-Fi-only 就主动擦除或忽略未知的小型 NV 分区。Wi-Fi / Bluetooth 的 MAC、校准参数或设备特定配置可能存放在 `persist` 或其他厂商分区。

### 4.3 整盘备份

如果工作机存储空间允许，第一次重新分区之前额外制作一份完整 eMMC raw dump。TB-X605F 只有 32GB，完整镜像的成本可以接受。

建议目录结构：

```text
backup/
├─ device-info/
├─ gpt/
├─ partitions/
├─ raw-emmc/
├─ checksums/
└─ README.md
```

所有备份完成后计算 SHA-256，并至少做一次可读性/尺寸校验。任何 GPT 修改之前都必须确认恢复材料真实存在，而不是只生成了空文件或错误尺寸的 dump。

---

## 5. 首次设备调查：不要先假设分区结构

已知社区资料表明 TB-X605F/Pie 属于早期 Treble 设备，常见状态为：

- arm64
- A-only 实际 slot 结构
- Android 9 vendor
- VNDK 28 / VNDK Lite
- stock Pie 非 SAR
- 现代 PHH/Treble GSI 通常使用 SAR/“AB-style system image”

但 Codex **必须以当前真机读取结果为准**，不要因为社区资料直接硬编码。

至少收集：

```text
adb shell getprop
adb shell cat /proc/cmdline
adb shell ls -l /dev/block/by-name
adb shell mount
adb shell df -h
adb shell cat /vendor/etc/fstab*
adb shell cat /system/vendor/etc/fstab*   # 若存在
fastboot getvar all
```

并分析：

- 实际 CPU ABI。
- slot 状态。
- Treble 状态。
- `ro.vndk.version`
- `ro.vndk.lite`
- `ro.product.first_api_level`
- system/vendor 的真实大小。
- dm-verity / AVB 状态。
- boot image header/version。
- recovery 的 SAR 识别情况。
- 当前 TWRP/Recovery 是否能正确挂载 system/vendor/data。

注意：所谓“AB GSI”经常描述的是 GSI 的 SAR 文件布局，并不意味着 X605F 会变成真正的 A/B slot 设备。

---

## 6. System 分区策略：不精简 ROM，空间不足就扩容

本项目明确选择：

- Evolution X Google Apps 版。
- 不使用 vanilla 版。
- 不因为 system 空间不足删除 Google Apps。
- 不为了适配旧分区裁掉 EvoX 核心功能。
- 允许缩小 userdata，扩大 system。

设备只有 32GB eMMC，但主要用途是副屏、文档和视频，因此 userdata 让出数 GB 是可接受的。

### 扩容原则

Codex 先根据：

- 当前 GPT。
- system 和 userdata 的物理相对位置。
- 当前 EvoX GApps GSI 的实际 raw ext4 image 大小。
- Android 17 后续增长余量。

自动计算新的布局。

优先方案是**从 userdata 分配空间给 system**。不要为了 system 扩容去移动/改写：

- boot
- vendor
- persist
- modem/NV
- firmware
- 其他硬件关键分区

除非真实 GPT 布局证明无法直接实现，并且 Codex 已验证另一种安全布局。

修改 GPT 时：

1. 保存原始 GPT。
2. 检查 userdata/system 的实际相邻关系。
3. 计算 sector，不允许照抄网上别人的 sector number。
4. 保证合理对齐。
5. 更新 primary + backup GPT。
6. 重新识别分区表。
7. 对受影响的 ext4 文件系统执行必要的离线检查/resize。
8. 确保 Recovery 和 bootloader 都能识别新大小。
9. 重新保存修改后的 GPT 快照。

system 的目标大小不要只做到“当前 A16 刚好能刷”，应留足未来 A17、GApps 和 Treble compatibility 的余量。

---

## 7. X605F 已知关键 SAR / PHH 补丁

重要参考：

- X605F SAR patch：
  https://github.com/sophiel-meow/modify_phh_gsi_sar
- 原始 XDA Treble 讨论（README 中链接）：
  https://forum.xda-developers.com/t/project-treble-gsi-images-on-smart-tab-m10-tb-x605f-l-and-p10-tb-x705f-l.4147201/
- SAR 线程：
  https://forum.xda-developers.com/t/android-s-gsi-system-as-root-on-on-smart-tab-m10-tb-x605f.4400689/

`modify_phh_gsi_sar` v3.1 的目的不是普通“开 SAR 开关”，而是针对 X605F/X605L/X705F/L 上 PHH GSI 的启动行为做兼容。

其已知核心行为包括：

1. 在 Recovery 中卸载 `/system` / `/system_root`。
2. 对 `/dev/block/bootdevice/by-name/system` 运行 `e2fsck -fp`。
3. 离线执行 `resize2fs`。
4. 根据 `ro.twrp.sar` 判断是否为 SAR。
5. SAR 时将 system block device 挂到 `/system_root`，再 bind `/system_root/system` → `/system`。
6. 修改 `/system/bin/rw-system.sh`。
7. 禁止 PHH GSI 在开机过程中再次尝试：
   - remount `/system` 为 RW
   - 在线执行 system resize
8. 处理旧 Android 11 时代的 `libstagefright_foundation.so` / VNDK APEX binding 兼容问题。

脚本自身明确说明：在 TB-X605F/L 上，GSI 启动时尝试把 system remount 为 RW 会导致设备 abort init，停在 Lenovo Logo。

**不要机械照搬 2022 年脚本。**

对于 Android 16/17，应先检查当前 TrebleDroid/PHH 代码是否还存在同样逻辑。原则是：

```text
旧补丁 = 已知故障样本 + 修复思路
不是 = 永远无脑运行的固定脚本
```

如果当前 EvoX/TrebleDroid 已经解决某一问题，不要重复 patch。需要保留的 X605F workaround 应重写成可维护的条件化补丁。

---

## 8. 第一阶段：现成 EvoX Android 16 GApps GSI bring-up

参考当前 EvoX Treble GSI：

https://github.com/Doze-off/EvoX_treble

Releases：

https://github.com/Doze-off/EvoX_treble/releases

当前有 Android 16 QPR2 Treble GSI，可用于第一阶段验证。

Evolution X 官方源码：

https://github.com/Evolution-X

官方当前说明：

- Android 17 `cnb`：当前主要开发重点。
- Android 16 `bka`：仍维护。
- Android 15 `vic`：仍有维护但不是本项目目标。

### 第一阶段目标

先不要碰 kernel 源码，保持：

```text
stock Lenovo Pie firmware
stock Lenovo vendor
stock Lenovo kernel
+ SAR/Treble compatibility
+ EvoX Android 16 GApps GSI
```

验证 GSI 能正常启动并建立 working matrix。

### 必测项目

#### 启动/基础

- 开机。
- boot animation。
- SetupWizard。
- Google 登录。
- 数据分区加密/解密情况。
- ADB。

#### 显示

- SurfaceFlinger。
- HWC/hardware composer。
- GPU。
- 方向旋转。
- 亮度。
- 灭屏/亮屏。
- 不允许长期依赖纯软件 composition。

#### 副屏用途重点

- Wi-Fi 稳定性。
- 低延迟网络传输。
- H.264 硬解。
- H.265 硬解（硬件实际支持范围内）。
- MediaCodec / OMX。
- 长时间播放视频。
- 长时间作为副屏。
- 亮屏数小时稳定性。
- USB 连接稳定性。

#### 其他硬件

- 触摸。
- Bluetooth。
- 扬声器。
- 3.5 mm 音频。
- 麦克风。
- 摄像头。
- 传感器。
- 充电。
- 电池电量。
- suspend/resume。
- 深度休眠。
- MTP。

### 调试命令/信息

Codex 自行使用并归档：

```text
adb logcat -b all
adb shell dmesg
adb shell cat /sys/fs/pstore/*
adb shell getprop
adb shell lshal
adb shell dumpsys SurfaceFlinger
adb shell dumpsys media.codec
adb shell dumpsys media.extractor
adb shell dumpsys power
adb shell dumpsys battery
adb shell mount
adb shell df -h
```

如果设备开不到 Android，则在 recovery/early boot 环境中优先抓：

- pstore / ramoops
- kernel log
- recovery log
- init failure 信息

---

## 9. X605F 兼容层必须独立维护

不要把 X605F 特判随意散落到 EvoX 或 TrebleDroid 源码各处。

建立类似结构：

```text
x605f-evox/
├─ README.md
├─ docs/
│  ├─ hardware-baseline.md
│  ├─ partition-layout.md
│  ├─ known-issues.md
│  └─ test-matrix.md
├─ recovery-assets/
├─ backup-metadata/
├─ patches/
│  ├─ treble/
│  ├─ sar/
│  ├─ media/
│  ├─ audio/
│  ├─ graphics/
│  └─ init/
├─ overlays/
├─ props/
├─ scripts/
└─ kernel/
```

每个 workaround 单独 commit，并写明：

- 原始症状。
- Android/EvoX 版本。
- 触发条件。
- 日志证据。
- 修复内容。
- 验证方法。
- 回滚方法。

不要一次同时大改 framework、vendor 和 kernel，否则无法定位 regression。

---

## 10. 第二阶段：自己编译 Evolution X Treble GSI

现成 GSI 跑通后，建立自己的构建环境。

### 上游参考

Evolution X：

https://github.com/Evolution-X

TrebleDroid：

https://github.com/TrebleDroid

重点项目包括：

- `device_phh_treble`
- `treble_app`
- `vendor_hardware_overlay`
- 相关 treble manifest / patches

历史 EvoX GSI 构建参考：

https://github.com/realahnet/treble_evo

注意该历史项目主要是旧 Android 分支的参考，不应该直接作为 2026 项目的长期上游。

当前 EvoX A16 Treble 构建参考：

https://github.com/Doze-off/EvoX_treble

### 构建要求

最终产物必须是：

- arm64
- 适用于 X605F 的 SAR/AB-style system layout
- Google Apps 版本
- 包含 X605F 所需 VNDK 28 / legacy vendor compatibility
- 不为减小镜像体积删掉 GMS / Pixel 体验 / EvoX 核心功能

当系统镜像变大时，优先调整物理 system 分区，不要通过做 vanilla/slim 版规避。

最终目标是：

```bash
./build-x605f-evox.sh
```

能够自动完成：

```text
同步源码
→ 应用 TrebleDroid patches
→ 应用 X605F patches
→ 生成 EvoX Treble 产品
→ 编译 Google Apps system.img
→ 校验镜像
→ 输出版本/commit/hash
```

不应依赖每次构建后人工 mount image、sed 文件再 repack。

---

## 11. Kernel：先证明 Lenovo 官方源码能够稳定自编

Lenovo/X605F kernel source：

https://github.com/Yahoo-Mike/android_kernel_lenovo_X605F

该仓库对应：

- TB-X605F Wi-Fi
- TB-X605L LTE
- msm-3.18.120
- Android Pie stock kernel
- `m10_msmcortex_defconfig`

仓库给出的基础编译方式为 arm64 + Android GCC 4.9，输出 `image.gz`。

### 必须分两步

#### Step A：clean self-built kernel

先完全不加入 ReSukiSU。

目标：

```text
Lenovo source
+ 尽可能接近 stock 的 config/toolchain
→ self-built clean kernel
→ 重新打包 boot.img
→ 真机启动
```

证明下面全部没有明显 regression：

- display
- touch
- Wi-Fi
- Bluetooth
- audio
- USB
- charging
- battery
- MediaCodec
- suspend/resume

如果 clean self-build 本身都不稳定，不允许继续叠 Root patch。

#### Step B：ReSukiSU

只有 clean kernel 完全可用后才集成 ReSukiSU。

---

## 12. ReSukiSU：唯一内核 Root 路线

项目：

https://github.com/ReSukiSU/ReSukiSU

文档：

https://resukisu.org/guide/build.html

Manual integration：

https://resukisu.org/guide/manual-integrate.html

当前 ReSukiSU 文档明确说明：

- 官方主要支持 GKI 2.0 / kernel 5.10+。
- 老内核 3.4+ 仍可以工作，但必须手工编译 kernel。
- Manual Hook 支持 Linux 3.4 到 6.18。
- 对于 X605F 的 3.18，应该按 non-GKI / Manual Hook 路线处理。

因此目标结构：

```text
Lenovo msm-3.18.120
        │
        ├─ CONFIG_KSU=y
        ├─ CONFIG_KSU_MANUAL_HOOK=y
        └─ 按 ReSukiSU 当前文档加入 3.18 适用 hooks
                  │
                  ▼
             ReSukiSU kernel
```

不要直接照 GKI 安装教程操作。

开发过程中必须始终保留：

1. 原厂 Lenovo stock boot/kernel。
2. 自编 clean kernel boot。
3. 自编 ReSukiSU kernel boot。

这样出现 bootloop 或异常时可以快速 A/B 比较：

```text
stock OK?
clean self-build OK?
ReSukiSU build FAIL?
```

若只有第三个失败，则保持 system/vendor 不动，集中分析 ReSukiSU kernel diff。

---

## 13. Android 17 迁移

Evolution X 官方目前已经把 Android 17 `cnb` 作为主要开发方向：

https://github.com/Evolution-X/manifest/tree/cnb

但 X605F 是：

```text
2018 年设备
Android 9 vendor
VNDK 28
Linux 3.18
```

所以不要直接从完全未知状态同时 bring-up A17 + SAR + kernel root。

推荐顺序：

```text
A16 + stock kernel
        ↓
A16 + X605F compatibility 稳定
        ↓
A16 + self-built clean kernel
        ↓
A16 + ReSukiSU
        ↓
A17 + 同一 vendor/kernel baseline
```

这样 A17 出问题时，可以直接把问题范围限制在 Android 17/Treble compatibility，而不是所有层一起变化。

---

## 14. 最终验收标准

项目不是以“能看到桌面”为完成标准。

### 日常使用必须达到

- EvoX 高版本稳定启动。
- Google Apps / Play Services 正常。
- 触摸正常。
- Wi-Fi 稳定。
- 屏幕亮度正常。
- 灭屏/亮屏稳定。
- 不随机重启。
- 长时间副屏使用稳定。
- HWC 正常或至少没有明显 software-composition 性能问题。
- 视频硬件解码正常。
- 音频正常。
- USB/ADB 正常。
- 充电和电量显示正常。
- suspend/resume 可接受。

### 折腾平台必须达到

- 已保存可用 ROW 9008/QFIL 包。
- 已保存 GPT。
- 已保存 `persist` 和其他设备特定小分区。
- 最好有完整 32GB eMMC raw backup。
- system 分区扩容布局有文档且可恢复。
- X605F patches 可重复应用。
- EvoX GSI 可以从源码重复构建。
- clean self-built kernel 可启动。
- ReSukiSU kernel 可启动并工作。
- 所有产物有 hash / git commit / build metadata。

---

## 15. Codex 的工作原则

1. **先测量，后修改。** 不猜 GPT、不猜 system 大小、不猜 slot。
2. **先备份恢复链，再修改 GPT。**
3. **优先自动执行，不让用户手工跑命令。**
4. **一次只改变一个主要层级。**
5. **永远保留可回退的 boot/system/GPT 基线。**
6. **日志优先，不靠“试试这个玄学开关”推进。**
7. **旧 XDA/PHH 脚本用于理解历史问题，不无脑执行。**
8. **不为了 system 太小改用 vanilla ROM；需要空间就扩 system。**
9. **系统必须是 Evolution X Google Apps 方向。**
10. **Kernel Root 只做 ReSukiSU。**
11. **主要用途仍然是副屏/视频，因此 HWC、MediaCodec、Wi-Fi、sleep/wake 的优先级高于摄像头等次要功能。**
12. **用户只做物理操作和视觉反馈。**

---

## 16. 建议的实际执行顺序

```text
[0] 建项目仓库并记录当前状态
 ↓
[1] 重新下载 TB-X605F Android 9 ROW 9008/QFIL 工厂包并校验
 ↓
[2] 读取设备真实属性/GPT/分区布局
 ↓
[3] 备份 GPT + persist + 全部小型设备特定分区
 ↓
[4] 条件允许则制作 32GB eMMC raw dump
 ↓
[5] 下载当前 EvoX A16 QPR2 GApps Treble GSI
 ↓
[6] 根据真实 system.img 与 GPT 规划 system 扩容
 ↓
[7] 修改 GPT、缩 userdata、扩 system、离线 resize/check
 ↓
[8] 完成 X605F SAR/Treble compatibility
 ↓
[9] stock Pie vendor + stock kernel 启动 EvoX A16
 ↓
[10] 建完整硬件 working matrix 并逐项修复
 ↓
[11] 建立自己的 Evolution X + TrebleDroid 源码构建树
 ↓
[12] 将 X605F workaround 全部源码化/条件化
 ↓
[13] 产出自己的 X605F EvoX GApps system.img
 ↓
[14] 编译 Lenovo 3.18.120 clean kernel 并验证
 ↓
[15] 集成 ReSukiSU Manual Hook 并验证
 ↓
[16] 长时间副屏/视频/休眠稳定性测试
 ↓
[17] 在保持 vendor/kernel baseline 不变的情况下迁移 EvoX Android 17
```

---

## 17. 主要参考链接

### Evolution X

- 官方组织  
  https://github.com/Evolution-X

- Manifest  
  https://github.com/Evolution-X/manifest

- Android 17 `cnb` manifest  
  https://github.com/Evolution-X/manifest/tree/cnb

### EvoX Treble GSI

- 当前 A16 Treble GSI 参考  
  https://github.com/Doze-off/EvoX_treble

- Releases  
  https://github.com/Doze-off/EvoX_treble/releases

- 历史 EvoX Treble 构建参考  
  https://github.com/realahnet/treble_evo

### TrebleDroid

- https://github.com/TrebleDroid

### TB-X605F SAR / PHH

- X605F SAR patch  
  https://github.com/sophiel-meow/modify_phh_gsi_sar

- XDA Project Treble 线程  
  https://forum.xda-developers.com/t/project-treble-gsi-images-on-smart-tab-m10-tb-x605f-l-and-p10-tb-x705f-l.4147201/

- XDA System-as-Root 线程  
  https://forum.xda-developers.com/t/android-s-gsi-system-as-root-on-on-smart-tab-m10-tb-x605f.4400689/

### Kernel

- Lenovo TB-X605F/L msm-3.18.120 source  
  https://github.com/Yahoo-Mike/android_kernel_lenovo_X605F

### ReSukiSU

- Repository  
  https://github.com/ReSukiSU/ReSukiSU

- Build guide  
  https://resukisu.org/guide/build.html

- Manual integration  
  https://resukisu.org/guide/manual-integrate.html

---

## 18. 开发机配置
当前开发机配置相对可观，可多核+大内存全开，且已有可用WSL。
Windows Git已通过gh cli登录。

---

## 19. 双机开发 / 编译 / 刷写协作

本项目允许 Codex 在两台机器之间分工工作，并以 **Git 仓库作为双端的统一同步中心和事实来源**。Codex 每次开始工作时应先识别当前所在操作系统，再自动采用对应角色，不要求用户手工在两台机器之间搬运源码、patch 或配置。

### Linux 机器：开发 / 编译机

当 Codex 当前运行在 Linux 环境时，该机器默认承担开发和构建工作，包括但不限于：

- 同步 Evolution X、TrebleDroid、kernel 等上游源码。
- 编写、修改和整理 X605F patches、overlays、props、scripts。
- 构建 EvoX Treble GSI。
- 编译 Lenovo 3.18.120 clean kernel。
- 集成并编译 ReSukiSU kernel。
- 对源码、patchset、构建脚本和构建结果生成 commit / hash / metadata。
- 分析由 Windows 刷写机提交回仓库的测试记录、日志摘要和 working matrix，并据此继续修复。

Linux 端原则上不承担必须连接真机才能完成的刷写工作；如果设备没有实际连接到该机，则不得假设可以直接执行 Fastboot、Recovery 或 EDL 操作。

### Windows 机器：真机刷写 / 调试机

当 Codex 当前运行在 Windows 环境时，该机器默认承担 TB-X605F 的实际设备操作，包括但不限于：

- ADB / Fastboot / Recovery / Qualcomm 9008 / QFIL 操作。
- 首次设备调查、GPT 和分区读取。
- GPT、persist、设备特定小分区及整盘 eMMC 备份。
- system 分区扩容及恢复验证。
- 刷写 EvoX GSI、boot.img、kernel 和其他测试镜像。
- 抓取 logcat、dmesg、pstore、recovery log 等真机日志。
- 执行硬件 working matrix、启动测试、回归测试和长时间稳定性测试。
- 将测试结论、日志摘要、设备状态和必要的 patch 反馈提交回 Git 仓库。

Windows 端应优先消费 Linux 端已经提交并标记好的可测试构建，而不是在刷写机上临时修改源码后直接刷入、导致双端状态不可追踪。

### Git 双端同步规则

Git 仓库是 Linux 开发机与 Windows 刷写机之间的主要同步机制。推荐流程：

```text
Linux 开发 / 修改 / 编译
        ↓
commit + push
        ↓
Windows pull
        ↓
刷写 / 真机测试 / 抓日志
        ↓
更新 test-matrix / known-issues / logs metadata
        ↓
commit + push
        ↓
Linux pull
        ↓
继续分析 / 修复 / 下一轮构建
```

Codex 应遵守：

1. 开始一轮工作前先 `git status`，确认没有未知的本地改动，再 fetch/pull 最新状态。
2. 一次主要修改对应一个清晰 commit；不要长期依赖只存在于某一台机器上的未提交改动。
3. X605F patch、overlay、脚本、配置、文档、测试矩阵和构建元数据必须进入 Git。
4. 真机测试结果必须能够追溯到具体的 system/kernel/boot 构建 commit 或 hash。
5. Windows 端发现问题后，应把可复现条件、日志摘要和当前构建 ID 一并记录，再同步给 Linux 端。
6. Linux 端完成修复后，应提交新的可测试 commit，由 Windows 端拉取后进行下一轮刷写验证。
7. 两端发生冲突时，以仓库历史和明确的 commit 为依据处理，不通过覆盖整个目录的方式强行同步。

### 不应直接放进普通 Git 历史的大文件

以下内容默认不要作为普通 Git blob 长期提交：

- 32GB eMMC raw dump。
- 完整 ROW/QFIL 工厂包。
- 大型 `system.img` / `vendor.img` / `userdata.img`。
- 大体积构建输出目录。
- 大量原始 logcat/dmesg 抓取文件。

这些内容应保存在各自机器的受控 artifact / backup 目录中，并在 Git 中记录：

- 文件名。
- 对应版本。
- SHA-256。
- 生成或下载日期。
- 来源或生成 commit。
- 保存位置说明。

如果确实需要跨机器分发大型构建产物，可使用 GitHub Releases、Git LFS 或其他明确的 artifact 存储方式；**Git 仓库本身主要保存可复现源码、patch、脚本、配置和元数据。**

最终要求是：无论 Codex 当前连接的是 Linux 还是 Windows，只要先同步同一个 Git 仓库，就能立即知道项目当前基线、上一轮测试结果、下一步任务以及对应的可回退版本，而不依赖用户人工描述两台机器各自做到了哪里。

