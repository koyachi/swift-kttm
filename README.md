# kttm

convert Keeping Two (by Jordan Crane) to Kindle .mobi.

http://whatthingsdo.com/comic/keeping-two/


## architecture

### scraper

- html解析
- 画像ダウンロード
- 画像順序情報ファイル出力

### image processer

- 画像を横2x縦3コマ単位で分割
- ダウンロードした時点で半端なコマ(2x1, 2x2等)画像はどうするか？

### mobi generator

TBD


## TODO

- split image file
  - guess suitable height
    - GPUImage, Hough Transform
      http://codezine.jp/article/detail/153
      http://nshipster.com/gpuimage/
      https://github.com/BradLarson/GPUImage/blob/master/framework/Source/GPUImageHoughTransformLineDetector.h
      http://www.sunsetlakesoftware.com/2014/06/30/exploring-swift-using-gpuimage
      検出した線から比較的寝ている線だけフィルタしても、コマのエッジ部分に寝ている線が無いと検出コマのエッジ検出が難しそう
    - 2値化した画像を横方向に捜査してドットが見つからないラインはコマ外と判定、でよさそう
- generate .mobi
  - prepare epub files(ncx, opf, etc)

## Links

- http://whatthingsdo.com/comic/keeping-two/
- https://github.com/neonichu/cato
- http://stackoverflow.com/questions/25126471/cfrunloop-in-swift-command-line-program
- http://stackoverflow.com/questions/24281362/accessing-temp-directory-in-swift
