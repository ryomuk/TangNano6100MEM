## RK2, RK3 diskの有効化

- os8.rk05は，RKのunitが2台((RKA0, RKB0)と(RKA1, RKB1))の設定でBUILDされている
ようなので設定を変更します．手順は下記の通り．

- モニタからOS/8を起動します．
```
Universal Monitor IM6100 (Control Panel)
07777
AC=0000 FLG,IF,DF=0000 SR=0000
] G23
```
- 登録されているデバイス(リソース)を確認します
```
.RES /L

1109 FREE BLOCKS

 NAME TYPE USER
 SYS  RK8E
 DSK  RK8E
 PTP  PTP 
 PTR  PTR 
 RXA0 RX8E
 RXA1 RX8E
 RKA0 RK8E
 RKB0 RK8E
 RKA1 RK8E
 RKB1 RK8E
 TTY  TTY 
 LPT  LPTR
 RF   RF08
 DTA0 TC08
 DTA1 TC08

OS/8 V3Q
```
- まだRKB3:は無いので下記はエラーになります．
```
.DIR RKB3:
RKB3 DOES NOT EXIST
```
- BUILDを起動します．
```
.R BUILD
```
- 登録されているデバイスを確認します．有効化されているデバイスにはアスタリスクが付いています．RKA2-3, RKB2-3は有効化されていません．
```
$PR

PT8E: *PTP  *PTR  
RX01: *RXA0 *RXA1 
RK8E: *SYS   RKA0  RKB0 
RK05: *RKA0 *RKB0 *RKA1 *RKB1  RKA2  RKB2  RKA3  RKB3 
KL8E: *TTY  
LS8E: *LPT  
RF  : *RF    NULL 
TC  : *DTA0 *DTA1  DTA2  DTA3  DTA4  DTA5  DTA6  DTA7 
```
- 全部で16個までしか登録できないので，いらないデバイスを削除します．
```
$UNLOAD RX01

$UNLOAD RF

$UNLOAD TC
```
- RK2(RKA2, RKB2)とRK3(RKB2, RKB3)を有効化します．
```
$IN RK05:RKA2-3,RKB2-3
```
- 確認します．
```
$PR

PT8E: *PTP  *PTR  
RK8E: *SYS   RKA0  RKB0 
RK05: *RKA0 *RKB0 *RKA1 *RKB1 *RKA2 *RKB2 *RKA3 *RKB3 
KL8E: *TTY  
LS8E: *LPT  
```
- BOOTします．
```
$BOOT
SYS BUILT
```
- リソースを確認します．
```
.RES /L

1109 FREE BLOCKS

 NAME TYPE USER
 SYS  RK8E
 DSK  RK8E
 PTP  PTP 
 PTR  PTR 
 RKA0 RK8E
 RKB0 RK8E
 RKA1 RK8E
 RKB1 RK8E
 RKA2 RK8E
 RKB2 RK8E
 RKA3 RK8E
 RKB3 RK8E
 TTY  TTY 
 LPT  LPTR

OS/8 V3Q
```
-  ディスクアクセスのログによると，BOOT時にSYS:上のファイルが書き換えられているようでした．rebootして確認します．
```
.
Universal Monitor IM6100 (Control Panel)
01210
AC=0000 FLG,IF,DF=4000 SR=0000
] S23
0023 : 0200 6007
0024 : 1200 6744
0025 : 0211 1032
0026 : 7607 6746
0027 : 5372 6743
0030 : 6203 1032
0031 : 0321 5031
0032 : 1630 0000
0033 : 0402 .
] G23

.RES /L

1109 FREE BLOCKS

 NAME TYPE USER
 SYS  RK8E
 DSK  RK8E
 PTP  PTP 
 PTR  PTR 
 RKA0 RK8E
 RKB0 RK8E
 RKA1 RK8E
 RKB1 RK8E
 RKA2 RK8E
 RKB2 RK8E
 RKA3 RK8E
 RKB3 RK8E
 TTY  TTY 
 LPT  LPTR

OS/8 V3Q
```
- RKB3:が読めるようになりました．
```
.DIR RKB3:

         

ABSLDR.SV   6           RL2SY .BH   2           DHLAAB.DG  13
CCL   .SV  31           RL20  .BH   2           DHTAAC.DG  17
DIRECT.SV   7           RL21  .BH   2           DHTABC.DG  13
PIP   .SV  11           RL2E  .BH   2           DHTMAB.DG  17
FOTP  .SV   8           ROMMSY.BH   1           DHTMBB.DG  17
SET   .SV  20           RXSY1 .BH   2           DHTMCA.DG  10
FUTIL .SV  27           RXSY2 .BH   2           DHTMDB.DG  15
BATCH .SV  10           RXNS  .BH   2           DHTMEB.DG  15
HELP  .SV   8           RXBSY1.BH   2           DHTMFC.DG  11
FRTS  .SV  26           RXBSY2.BH   2           DHTSAB.DG  17
RKBOOT.SV   2           RXBNS .BH   2           DHTSBB.DG  17
BASIC .SV  11           RX28C .BH   2           DHTSCB.DG  15
BLOAD .SV  10           RX78C .BH   2           DHTSDB.DG  13
BCOMP .SV  26           TC08SY.BH   1           DHTSEA.DG  10
BRTS  .SV  25           TC08NS.BH   2           DHTSFA.DG   3
CHESS .SV  28           TD8ESY.BH   2           DHVCAA.DG  13
ADVENT.SV 129           TD8EA .BH   2           DHVTAB.DG  11
BASIC .UF   2           TD8EB .BH   2           DHVTBA.DG   4
BASIC .OV  16           TM8E  .BH   2           DHVTDA.DG  16
RK8EA .SY  50           VXSY  .BH   1           DIADFA.DG  11
RK8EB .SY  50           VXNS  .BH   1           DIAFBA.DG  17
RKS8EA.SY  50           RECOVR.BI   2           DIDBAA.DG   7
RKS8EB.SY  50           ADVENT.DA 145           DIDFAC.DG   7
HELP  .HL  67           ADVENT.LD 143           DIDFBA.DG  10
GAMES .HL  63           ADVENT.TX 200           DIDFCA.DG  17
ASR33 .BH   1           BANNER.BA  23           DILTCA.DG   6
BAT   .BH   1           FUTIL .TX 316           DILTDA.DG  10
CR8E  .BH   2           DECX8 .TX  64           DILVAA.DG  10
CS    .BH   2           OS8   .TX  58           DIRTAB.DG  14
DF32SY.BH   1           DIAG  .TX  88           DITCBA.DG  11
DF32NS.BH   1           TITLE .TX   7           DITCCA.DG   9
DUMP  .BH   2           TYPSET.DG  10           DITCDA.DG  15
KL8E  .BH   2           SHELLY.DG   4           DIUDAC.DG  17
LINCSY.BH   1           AUVAAA.DG  16           DIVTBA.DG   8
LINCNS.BH   2           AUVBAB.DG  16           DIVTCA.DG  11
LPSV  .BH   1           AUVCAA.DG   6           DJADAC.DG  16
LQP   .BH   2           AUVDAB.DG   9           DJVKAB.DG  15
MODLQP.BH   2           AUVEAD.DG   8           DIRECT.TS   6
PT8E  .BH   1           DGV5AB.DG  13           RKS8ES.PA  37
RF08SY.BH   1           DHADAA.DG  11           RKSFMT.LC   6
RF08NS.BH   1           DHCMAA.DG  10           RKSREL.LC   9
RK08SY.BH   1           DHCRAA.DG  10           RKSLES.LC  16
RK08NS.BH   1           DHDHAA.DG   7           RKSWCT.LC   8
RK8EA .BH   1           DHDHCA.DG   2           RKSCTL.LC  16
RK8EB .BH   1           DHDKAA.DG  15           RKCOPY.LC   5
RK8ENS.BH   2           DHDPAD.DG  18           JDAY8E.SY  50
RKS8EA.BH   1           DHDRAB.DG  11           RKSFMT.DG   6
RKS8EB.BH   1           DHDRHA.DG  11           RKSWCT.DG   8
RKS8NS.BH   2           DHICAA.DG  21           RKSCTL.DG  16
RLSY  .BH   2           DHKGAB.DG  14           RKSREL.DG   9
RL0   .BH   2           DHKLBB.DG  13           RKSLES.DG  16
RL1   .BH   2           DHKLCD.DG   8           RKCOPY.DG   5
RLC   .BH   2           

 157 FILES IN 2762 BLOCKS -  430 FREE BLOCKS

.

```