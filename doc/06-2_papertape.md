# paper tape software
- SDメモリで動作する紙テープエミュレータを実装しました。
- インターネット上のPDP8関連のアーカイブから入手できる紙テープのイメージを全く加工せずにddで書き込むだけでロードと起動ができることを目標にしました．
- tangnanoのSW1で8個のtape imageから1つ選択します．
- 0が1024個続くとEnd of Tapeと判断し読み込みは停止します．状態はMatrix LEDに表示されます．(LEDの位置はtop.v参照．)
- モニタからGで起動したときや読み込みの途中でEOTでないのにHALTで止まったらCONTを押して継続します．

## boot loader
- RIM loader(開始アドレス=7756)をいちいちモニタで書き込むのは面倒なので，メモリ上に置いてあります．(当時はパネルスイッチでパチパチ入力していたようですが．)
- ついでにbinary loader(開始アドレス=7701)も置いておきましたが，ちょっとチートな気もします．binary loader自身もちゃんとRIM loaderで読む方が本格的な気分になれます．(mem.vのdefine文で無効にできます．)
- メモリの初期値は今後変わるかもしれないので，最新の情報はmem.vを確認して下さい．

## 動作例
### 4k BASIC (edusystem 10)
- http://www.bitsavers.org/bits/DEC/pdp8/papertapeImages/basic/edusystem-10/
- ファイル名: dec-08-ed10a-a-pb-new.ptp
- 最初にbinary loader，続いてプログラムが格納されている．
- RIMローダーを起動するだけで自動的に実行された．
```
Universal Monitor IM6100 (Control Panel)
7777
] G7756
# HALTで止まっていたらCONTボタンを押す

SELECT THE SMALLEST SET OF FUNCTIONS NEEDED FROM THE FOLLOWING CHOICES
ATN         ! !X! ! ! ! ! !
LOG+EXP     ! !X!X! ! ! ! !
SIN+COS+TAN ! !X!X!X! ! ! !
DEF(FN)     ! !X!X!X!X! ! !
SQR         ! !X!X!X!X!X! !
RND         ! !X!X!X!X!X!X!

OPTION       A B C D E F G

TYPE OPTION LETTER?G
DO SUBSCRIPTS START AT 0 OR 1?0
READY.
```

### 8k BASIC
- https://computermuseum.informatik.uni-stuttgart.de/ftp/dec/papertapes/basic-8/
- ファイル名: BASIC8.BN
- 上記リンクにソースとマニュアルもあり．
- binary loaderでロード
- 開始アドレス=1000
```
Universal Monitor IM6100 (Control Panel)
7777
] G7701
# HALTで止まったらCONTを押す．
# End of TapeになったらCPREQでモニタを起動
Universal Monitor IM6100 (Control Panel)
7670
] G1000

READY.


PRINT "HELLO 8K BASIC"
HELLO 8K BASIC
```

### FOCAL
- http://www.bitsavers.org/bits/DEC/pdp8/From_pdp8.hachti.de/hachti-pdp8-tapes/
- ファイル名: DEC-08-AJAE-PB.bin
- 開始アドレス=0200
- binary loaderで起動します．
- 末尾のゴミ(後述)のせいでDFが1になったり，244番地が書き替えられてたりするので手動で修正します．
```
Universal Monitor IM6100 (Control Panel)
7777
] G7701
# 途中で5〜6回くらい止まるのでCONTで読込を継続．
# End of TapeになったらCPREQでモニタに戻ってDFと244番地を修正して起動．

Universal Monitor IM6100 (Control Panel)
7671
] F0
0000
] S244
0244 : 3044 4554
0245 : 1124 .
] G200

CONGRATULATIONS!!
YOU HAVE SUCCESSFULLY LOADED 'FOCAL,1969' ON A PDP-8 COMPUTER.


SHALL I RETAIN LOG, EXP, ATN ?:YES

PROCEED.

*1.10 TYPE "HELLO FOCAL!" !
*W
C-FOCAL,1969

01.10 TYPE "HELLO FOCAL!" !
*GO
HELLO FOCAL!
*

```
末尾のこのあたりのデータが悪さをしているようです．削除してもいいのですが，上記修正で直ったのでとりあえずそれで済ませました．
```
# /usr/bin/od -t o1 DEC-08-AJAE-PB.bin | less
0017600 000 000 000 000 000 000 000 000 000 000 000 252 125 252 056 073
0017620 052 056 000 000 000 000 000 000 000 000 000 000 000 000 000 000
0017640 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000
*
0020100 000 000 000 000 000 000 102 044 030 044 102 201 102 044 030 044
0020120 102 201 102 044 030 044 102 201 314 000 000
```

### LISP
- http://www.bitsavers.org/bits/DEC/pdp8/papertapeImages/set1/
- ファイル名: DECUS_8_102A_LISP.BIN
- 開始アドレス=3000 (自動実行)
- 自動実行なので，Self-Starting Binary Loader を試してみました．
  - https://deramp.com/downloads/mfe_archive/011-Digital%20Equipment%20Corporation/01%20DEC%20PDP-8%20Family%20Software/02%20Paper%20Tape%20Utilities/DEC-8E-XBINA%20Binary%20Loader/
  - DEC_8E_XBINA_A_PB.BIN

```
# G7756でRIM Loaderを起動してSS Bin Loaderを読む．
Universal Monitor IM6100 (Control Panel)
7777
] G7756
# EOTが点灯して止まったら，SW1でイメージファイルをLISPに変更してCONT
# 再度EOTが点灯するまで5回くらいCONT
# EOTの点灯と同時にLISPが起動する．(起動メッセージは無い)

()()
 NIL
CAR((A B C))
 A

```
