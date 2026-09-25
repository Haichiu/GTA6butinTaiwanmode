# GTA6 but in Taiwan mode

一款諷刺台灣交通法規的 3D 機車小遊戲：你不是輸在技術，而是輸給反直覺的法規。
每張罰單都引用真實條文與裁罰基準表金額（見 [docs/laws.md](docs/laws.md)）。

- 引擎：Godot 4.7（GDScript，Compatibility 渲染器）
- 執行：`godot --path .`
- 測試：`tests/run.sh`（全部關卡，約 10 秒）或 `tests/run.sh 3 5`（指定關卡）
- 截圖：`godot --path . res://tests/shot.tscn -- <輸出資料夾>`
- 網頁版：`godot --headless --path . --export-release "Web" build/web/index.html`，本機測試用 `python3 -m http.server 8060 --directory build/web`
- 規劃：[docs/plan.md](docs/plan.md)

## 素材授權
- 3D 模型：Kenney City Kit (Roads)、Car Kit、City Kit (Commercial)，CC0（www.kenney.nl）
- 字型：Noto Sans TC，SIL Open Font License 1.1（assets/fonts/LICENSE-OFL.txt）
