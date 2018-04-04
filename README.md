# BF です
ビットフライヤーのpublic apiから取得した最終取引価格を1~60分の間隔で集計するgemです。

```
1m: 932051 ~ 934133 (2082) 5m: 931161 ~ 933118 (1957) 10m: 931448 ~ 934133 (2685) 30m: 931983 ~ 934867 (2884) 60m: 931482 ~ 935966 (4484) 上 下 下 下
1m: 932051 ~ 934133 (2082) 5m: 931161 ~ 933341 (2180) 10m: 931448 ~ 934133 (2685) 30m: 931983 ~ 934867 (2884) 60m: 931482 ~ 935966 (4484) 上 下 下 下
1m: 932224 ~ 934133 (1909) 5m: 931161 ~ 933350 (2189) 10m: 931448 ~ 934133 (2685) 30m: 931983 ~ 934867 (2884) 60m: 931482 ~ 935966 (4484) 上 下 下 下
1m: 932276 ~ 934133 (1857) 5m: 931000 ~ 933378 (2378) 10m: 931448 ~ 934133 (2685) 30m: 931983 ~ 934867 (2884) 60m: 931482 ~ 935966 (4484) 上 下 下 下
```

## Installation
### Gemfile
```
gem 'bf', github: 'jiikko/bf', path: '/Users/koji/src/bf_tools'
```

### rails app で動かすなら
```
bundle exec rails bf_engine:install:migrations
```
## Usage
```
bit/run.rb
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
