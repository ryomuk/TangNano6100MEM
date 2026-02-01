# ベアメタル

下記のような手段でプログラムをメモリに格納し，ベアメタルで動作させることができます．
- universal monitor(使い方は[debugtool.md](07_debugtool.md)参照)でメモリに書く
- アセンブラで作成したバイナリデータやmem.vに変換してビルド
- 紙テープイメージから作ったメモリデータをmem.vに変換してビルド

### Universal Monitorでメモリに書いて実行
```
# CPREQボタンを押してモニタを起動
Universal Monitor IM6100 (Control Panel)
7777
] S200
0200 : 0000 6032
0201 : 0000 6031
0202 : 0000 5201
0203 : 0000 6036
0204 : 0000 6046
0205 : 0000 6041
0206 : 0000 5205
0207 : 0000 5200
0210 : 0000 .
] G200
# HALTで止まっていたらCONTボタンを押す
# キー入力がechoされる
Hello!
Keyboard echo test
```

### アセンブラで作ったバイナリからメモリデータへの変換
- [tools/unimon/im6100/bin2v.pl](../tools/unimon/im6100/bin2v.pl)
を参考にして下さい．コントロールパネル空間用になっているので，適宜変更して下さい．

### 紙テープイメージからメモリデータへの変換
- 紙テープエミュレータを実装する前は，紙テープのimageをFPGAの初期メモリデータmem.vに変換して再ビルドするという手順で紙テープソフトを実行しました．変換用のプログラムはこれ→[tools/papertape/ptp2v.c](../tools/papertape/ptp2v.c) 
- テープの末尾のゴミを手作業で修正する必要があります．(それほど多くはない)
- 起動アドレスを7776番地に書き込みます．(CPのunimonからGで実行しても可．)
- リセット時に7777でHALTするので，CONTボタンを押して実行．

#### FOCAL
```
$ ptp2v DEC-08-AJAE-PB.bin > mem.v
開始アドレスを修正 (そのままにしてCPのunimonからG200でも可)
mem['o7776]='o7777; // set start address here
↓
mem['o7776]='o0200;
```
ビルドしてFPGAに書き込んで起動．
```
CONGRATULATIONS!!
YOU HAVE SUCCESSFULLY LOADED 'FOCAL,1969' ON A PDP-8 COMPUTER.


SHALL I RETAIN LOG, EXP, ATN ?:YES

PROCEED.

*
```

#### 4K BASIC
```
$ ptp2v dec-08-ed10a-a-pb-new.ptp > mem.v
開始アドレスを修正
mem['o7776]='o7777; // set start address here
↓
mem['o7776]='o0200;
```
ビルドしてFPGAに書き込んで起動．
```
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

#### 8K BASIC
```
$ ptp2v BASIC8.BN > mem.v
開始アドレスを修正
mem['o7776]='o7777; // set start address here
↓
mem['o7776]='o1000;
```
ビルドしてFPGAに書き込んで起動．
```

READY.
```

#### LISP
```
$ ptp2v DECUS_8_102A_LISP.BIN > mem.v
ゴミを削除
mem['o3000]='o7407; ← これを消す．(開始アドレスなので，ちゃんと変換できてないだけ本来はゴミではない)
開始アドレスを修正
mem['o7776]='o7777; // set start address here
↓
mem['o7776]='o3000;
```
ビルドしてFPGAに書き込んで起動．
```
CAR((A B C))
 A

CDR((A B C))
 (B C)

CONS(A (B C D))
 (A B C D)


DEFINE (((FIB (LAMBDA (N)
         (COND ((EQUAL N 0) 0)
               ((EQUAL N 1) 1)
               (T (PLUS (FIB (MINUS N 1)) (FIB (MINUS N 2))))))
)))
 (FIB(LAMBDA(N)(COND((EQUAL N 0)0)((EQUAL N 1)1)(T(PLUS(FIB(
MINUS N 1))(FIB(MINUS N 2)))))))


FIB(10)
 55
```

