# BF
[![Build Status](https://travis-ci.org/jiikko/bf.svg?branch=master)](https://travis-ci.org/jiikko/bf)

* BF板取引支援ライブラリ

## Installation
set api key of bf.
```
$ cp bf_config.sample.yaml bf_config.yaml
$ edit bf_config.yaml
```
```
$ echo 'create database bf_cli_development' | mysql -uroot
```

### Gemfile
```
gem 'bf', github: 'jiikko/bf', branch: :master
```

## Usage
```
bit/run.rb
```
```
COUNT=5 QUEUE=normal be rake resque:workers
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## TODO
* 連続して取得できていることを可視化したい
* 取引所のステータスをDBにいれる(いまレディス)
  * 30分以内に負荷が高いと注文を入れない、という機能をいれたい(注文が遅れるとつらい)
* redis のワーニングをけす
  * `The client method is deprecated as of redis-rb 4.0.0, please use the new _clientmethod instead. Support for the old method will be removed in redis-namespace 2.0.`
* ログ出力への出力もしつつ、ログテーブルにも出力したい
  * 買いが失敗した旨のログとか、アクションが必要な旨のログも見れるようにする
* タイムアウトを迎えて注文をキャンセルする時は、最終取引価格が近い時はキャンセルをしない
  * キャンセル注文と送った直後に成約すると売り注文が走らなくなるため

## 買い注文を入れるロジック
* 下下下上 かつ 0,0,0,100 は発注しない
  * 短時間で下落している
* 1,5,10で分散が一定値に収まるなら発注する
  * レンジで上下しているとみなす
* 下上xx   かつ 最小差額(赤いバー)(独自指標) が0の時に1分足最小価格で発注する

## カラムに変更があった場合
* テーブルに変更がある場合databaseをdropするとか不足しているカラムを追加してください
  * createのmigratioファイルのみを管理していく
