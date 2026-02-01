## SDメモリ
- RKディスクエミュレータと紙テープエミュレータ用のディスクイメージをSDメモリに書き込み，TangNano 20KのSDメモリスロットに入れます．
- fat等のファイルシステムは持たず，ddでブロックの先頭から生で使用します．

## メモリイメージの構成
- まだ開発途上なので変更する可能性があります．
- 基本的にはtop.vのコメントに書いてあります．下記に再掲します．
- SW1で先頭ブロックをシフトして紙テープイメージを選択できるようになっています．

```
// RK Disk
// 256 word x 16 sector x 203 cyl(track) x 2 surface
// 6496 * 256word(512byte) block (1,662,976 word)
//
// 1 block = 256word = 512B = 01000B
// SD memory block
// each RK05 disk image uses first 6496 block in 8192 block.
// (DRIVE_BLOCK_SIZE = 8192 (= 16 * 2 * 256))
//        0- 8191: RK0 (00000000)
//     8192-16383: RK1 (00020000)
//    16384-24575: RK2 (00040000)
//    24576-32767: RK3 (00060000)
//    32768-33791: TP0 (00100000)
//    33792-34815: TP1 (00102000)
//    34816-35839: TP2 (00104000)
//    35840-36863: TP3 (00106000)
//    36864-37887: TP4 (00110000)
//    37888-38911: TP5 (00112000)
//    38912-39935: TP6 (00114000)
//    39936-40959: TP7 (00116000)
//
```

複数のディスクイメージをまとめてsdメモリ用のイメージsd.dskを作る例．

```
# disk images
dd if=os8.rk05                  of=sd.dsk bs=512
dd if=diag-games-kermit.rk05    of=sd.dsk bs=512 seek=8192  conv=notrunc
dd if=advent.rk05               of=sd.dsk bs=512 seek=16384 conv=notrunc
dd if=sample.rk05               of=sd.dsk bs=512 seek=24576 conv=notrunc
# tape images
dd if=dec-08-lbaa-pm            of=sd.dsk bs=512 seek=32768 conv=notrunc
dd if=DEC_8E_XBINA_A_PB.BIN     of=sd.dsk bs=512 seek=33792 conv=notrunc
dd if=dec-08-ed10a-a-pb-new.ptp of=sd.dsk bs=512 seek=34816 conv=notrunc
dd if=BASIC8.BN                 of=sd.dsk bs=512 seek=35840 conv=notrunc
dd if=DEC-08-AJAE-PB.bin        of=sd.dsk bs=512 seek=36864 conv=notrunc
dd if=DECUS_8_102A_LISP.BIN     of=sd.dsk bs=512 seek=37888 conv=notrunc
```
