# SpriteAnimGenerator

SpriteAnimGenerator 是一个 Godot 编辑器插件，用于将角色序列帧图快速切分并导出为 SpriteFrames 资源。

当前插件主要面向由 Universal LPC Character Generator 一类工具生成的角色 spritesheet，但同样适用于规则网格切片的角色动画图集。

## 功能特性

- 从单张 spritesheet 按行列切分动画帧
- 自动检测每一行中可见帧数量
- 支持逐行动画命名
- 支持预览生成后的 AnimatedSprite2D
- 预览区域支持网格布局与滚动查看
- 将全部动画导出为单个 SpriteFrames 资源文件

## 环境要求

- Godot 4.x

## 安装方式

1. 将仓库放入你的 Godot 项目目录。
2. 打开项目后进入 Project -> Project Settings -> Plugins。
3. 启用 Sprite Animation Generator 插件。
4. 启用后，插件面板会出现在编辑器右侧停靠区域。

## 使用说明

### 1. 选择序列帧图片

点击面板中的 Select Sprite2D Resource...，选择一张角色 spritesheet 图片。

### 2. 设置切片参数

- HFrames: 每行帧数
- VFrames: 总行数
- FPS: 动画播放速度

插件会根据 HFrames 和 VFrames 计算每个格子的尺寸，并自动扫描每一行中实际存在图像内容的帧数。

### 3. 设置动画名称

在左侧每一行的输入框中填写动画名称。默认名称格式为 Anim0、Anim1、Anim2 ...

注意：批量生成前，必须至少有一个动画名称为 default，否则插件会提示：请设置default动画后再导出。

### 4. 预览动画

- 点击某一行的 Generate，可以只生成该行动画预览。
- 点击 Generate All，可以生成全部动画预览。

预览会以网格方式排列，并在每个动画下方显示名称。

### 5. 导出 SpriteFrames

点击 Export Resource File 后：

1. 会弹出保存文件对话框
2. 选择保存路径和文件名
3. 插件会将所有有效动画打包为一个 SpriteFrames 资源
4. 导出格式支持 .tres 或 .res

导出的 SpriteFrames 资源中只包含动画帧数据，不包含预览节点在编辑器中的摆放位置。

## 导出规则

- 每一行对应一个动画
- 动画名称来自该行的 LineEdit 输入框
- 帧数来自该行实际检测到的可见图像数量
- 空行不会被导出
- 动画速度统一使用当前 FPS 设置

## 项目结构

addons/sprite_anim_generator/

- editor.gd: 编辑器主逻辑
- editor.tscn: 编辑器界面场景
- sprite_anim_generator.gd: Godot EditorPlugin 入口
- plugin.cfg: 插件描述文件

## 已知说明

- 当前导出的是 SpriteFrames 资源，不会自动创建 AnimatedSprite2D 节点或场景。
- 预览区域中的布局、边框和标签只用于编辑器显示，不会写入导出资源。
- 如果修改了 HFrames 或 VFrames，预览会被重新构建。

## 许可证

本项目使用 MIT License。详见 [LICENSE.md](LICENSE.md)。