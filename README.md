# TangNano6100MEM
Memory systems and peripherals implemented on Tang Nano 20K for Intersil IM6100 PDP-8 Processor

This document is written mostly in Japanese, so please use machine translation if necessary.

![](images/title.jpg)
# 概要
- PDP-8の命令セットを持つCPU「Intersil IM6100」のメモリシステムと周辺回路をFPGA(TangNano20K)上に実装する試みです．
- FPGAに実装するのはメモリ，UART, HDDなどの周辺装置の部分だけで，CPU自体は本物を使用します．ソフトウェアやFPGAによるシミュレータやエミュレータではなく，実物のCPUを動かします．
- "TangNano6100"だとTangNano上にIM6100を実装したみたいな名前になってしまうので，"MEM"を付けて"TangNano6100MEM"という名前になっています．
- モニタプログラムとして，Haruo Asano氏による[Universal Monitor](https://electrelic.com/electrelic/node/1317)IM6100版をControl Panel空間で動くように改変したものを搭載しました．MITライセンスだったので，使用した部分のソースを同梱しています．

## 最近の主な話題
- 2026/01/28: 初版公開
- 2026/02/01: version 20260201, 紙テープエミュレータ実装
- 2026/02/02: version 20260202, 割り込み関連のバグ修正
  
## 主なファイル一覧
```
.
├── doc                      : 説明用文書
├── hdl                      : Gowin EDA用プロジェクト
│   ├── old                 : 旧版のバックアップ(あれば)
│   └── TangNano6100MEM_project: HDLソース一式
│       └── src
│            ├── dbglog.v   : debug log用モジュール
│            ├── mem.v      : メモリ初期データ(OS/8 bootloader)
│            ├── mem_cp.v   : CPメモリデータ(unimon)
│            ├── sdhd.v     : HDエミュレータモジュール
│            ├── sdtape.v   : 紙tapeエミュレータモジュール
│            ├── switch.v   : スイッチ用モジュール
│            ├── TangNano6100MEM_project.sdc : 時間制約(適当)
│            ├── tn20k.cst  :  物理制約(ピンアサイン)
│            ├── top.v      : メインプログラム
│            ├── uart.v     : uartモジュール
│            ├── ws2812.v   : WS2812モジュール
│            └── ws2812_matrix.v : WS2812 matrix用モジュール
├── images                   : 文書用画像ファイル
├── LICENSE
├── pcb
│   └── rev2.1 :  回路図，基板データ等(KiCAD 9用)
├── README.md   : このファイル
└── tools
    ├── papertape
    │   └── ptp2v.c    : 紙テープバイナリ変換用ソフト
    └── unimon          : Universal Monitor
        ├── im6100      : IM6100 Control Panel版
        └── LICENSE.txt : 上記のライセンスファイル

```

各種説明は[doc/](./doc/)に項目に分けて記載しています．
- [更新履歴](doc/01_updatelog.md)
- [基板関連](doc/02_PCB.md)
- [FPGA関連](doc/03_FPGA.md)
- [インターフェース](doc/04_Interface.md)
- [SDメモリ](doc/05_SDmemory.md)
- [応用例](doc/06-0_applications.md)
  - [ベアメタル](doc/06-1_baremetal.md)
  - [紙テープソフト](doc/06-2_papertape.md)
  - [OS/8](doc/06-3_os8.md)
- [デバッグツール](doc/07_debugtool.md)
- [関連情報・参考資料](doc/08_references.md)

## その他
以下，雑多な情報です．

### 動作状況
- 紙テープソフトやOS/8およびOS/8上で動く言語処理系などがある程度動作します．
- OS/8のBASICで簡単なプログラムを入力したりセーブ/ロードしたりできます．
  - STRTRK.BAやSNOOPY.BAが動きました．
- コントロールパネル空間でUniversal Monitorが動きます．

### 既知の問題
- ステップ実行後に戻ってくるとおかしくなることがある．
- ~~OS/8版のFOCALが動かない．おそらく割り込み関連の問題．~~ → やはり割り込みの問題でした．20260202版で修正して解決．
- ~~OS/8でDIR SYS: はできるが DIR RKA0: は止まる．~~ → PDP/8ハンドブックの誤植が原因でした．RK_DONEフラグを修正したら動くようになりました．
- ~~OS/8 BASICでSTRTRK.BAやSNOOPY.BAが動かない．~~ 動きました．

### 今後の予定，ToDo
- いろいろ動かないところのデバッグ．
- 磁気テープドライブエミュレータ実装．(紙テープは実装済)
- Universal Monitor関連．
  - コンテキスト保存，復帰．

<!--
# 動画
- [UNIX V6 on DEC DCJ-11 (PDP-11) with Tang Console 138K](https://www.youtube.com/watch?v=6rK0t8tJp9Y)
-->

