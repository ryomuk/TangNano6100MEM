## SDメモリ
- RKディスクエミュレータ用のディスクイメージをSDメモリに書き込み，TangNano 20KのSDメモリスロットに入れます．
- fat等のファイルシステムは持たず，ddでブロックの先頭から生で使用します．
- 今後，紙テープ，磁気テープ用にも使用する予定です．

## メモリイメージの構成
- まだ開発途上なので変更する可能性が高いです．
- 基本的にはtop.vのコメントに書いてあります．下記に再掲します．
- SW1で先頭ブロックをシフトして複数のイメージを選択できるようになっていますが，まだ適当な実装で暫定的なものです．

```
// SD memory block
// each RK05 disk image uses first 6496 block in 8192 block.
// (DRIVE_BLOCK_SIZE = 8192 (= 16 * 2 * 256))
//        0-  8191: RK0 (00000000)
//     8192- 16383: RK1 (00020000)
//    16384- 24575: RK2 (00040000)
//    24576- 32767: RK3 (00060000)
//
// # sample for making a sd image from multiple disk images
// dd if=rk0 of=sd.dsk
// dd if=rk1 of=sd.dsk seek=8192  conv=notrunc
// dd if=rk2 of=sd.dsk seek=16384 conv=notrunc
// dd if=rk3 of=sd.dsk seek=24576 conv=notrunc
```
