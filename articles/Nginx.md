# これだけNginx

## 概要

- 1つのマスタープロセスと複数のワーカープロセスで動く
- マスタープロセスは構成ファイルの読み取りやワーカープロセスの維持をする
- 実際のリクエストを処理するのはワーカープロセス

### 設定ファイル

- 設定ファイルの場所は`/etc/nginx/nginx.conf`
- 設定のことをディレクティブと呼ぶ
  - `{}`でネストできるディレクティブをブロックディレクティブ(コンテキスト)と呼ぶ
  - コンテキストの外にあるディレクティブはメインコンテキストに存在すると言える
- 最小構成は↓のような感じ。これでとりあえずNginxのデフォルトのindex.htmlが表示できる
  - `nginx -V`で分かるようにNginxのビルドパラメータで指定しているものは改めて設定ファイル上で宣言しなくても良いのだと思う

```nginx
events {}

http {
    server {
        root  /usr/share/nginx/html;
    }
}
```

## 主なディレクティブ

### 基本

#### error_log

- Syntax: error_log file [level];
- Default: error_log logs/error.log error;
- Context: main, http, mail, stream, server, location

エラーログの保存先を指定する。  
NginxのDockerイメージだと`/var/log/nginx/error.log notice`になっているのでこれにするのがベターかな。

#### events

- Syntax: events { ... }
- Default: —
- Context: main

接続処理に影響を与えるディレクティブ用のコンテキスト。

#### pid

- Syntax: pid file;
- Default: pid logs/nginx.pid;
- Context: main

エラーログの保存先を指定する。  
NginxのDockerイメージだと`/var/run/nginx.pid`になっているのでこれにするのがベターかな。

#### user

- Syntax: user user [group];
- Default: user nobody nobody;
- Context: main

ワーカープロセスの実行ユーザ。  
NginxのDockerイメージだとビルドパラメータで`nginx`を指定しているので明示的に書く必要は無いけどお作法的に書いておくと良さげ。

#### default_type

- Syntax: default_type mime-type;
- Default: default_type text/plain;
- Context: http, server, location

デフォルトのMIMEタイプ。  
NginxのDockerイメージでは`application/octet-stream`。  
デフォルトの`text/plain`は「人間が読めるもの」を期待しているのでバイナリなどを返す場合は嘘になる。  
また、mdnによると「未知の種類のファイルは、このタイプを使用するべき」なので、`application/octet-stream`を指定するのが無難。
<https://developer.mozilla.org/ja/docs/Web/HTTP/MIME_types/Common_types>

#### http

- Syntax: http { ... }
- Default: —
- Context: main

HTTPサーバ用のコンテキスト。

#### listen

- Syntax: 長いので省略。基本的には`listen address[:port]`
- Default: listen *:80 |*:8000;
- Context: server

リクエストを受け入れるポート。

#### location

- Syntax:
  - location [ = | ~ | ~* | ^~ ] uri { ... }
  - location @name { ... }
- Default: —
- Context: server, location

リクエストされたURLに応じた設定ができるコンテキスト。  
正規表現かprefixで指定ができる。  
文字列評価の挙動は修飾子でコントロールできる。

- =: 完全一致
- なし: 前方一致
- ^~: 前方一致 (一致したら正規表現のlocationを評価しない)
- ~: 正規表現 (大文字小文字を区別する)
- ~*: 正規表現 (大文字小文字を区別しない)

locationが複数ある場合、評価する順番がちょっと複雑なので注意。

1. 完全一致`=`にマッチしたらそのlocationを選んで終了
1. 前方一致`^~`、`なし`のlocationを判定し、最も長い文字列がマッチしたものを記録する（ただし、最も長い文字列がマッチしたlocationが`^~`だったらそのlocationを選んで終了）
1. 正規表現`~`、`~*`のlocationを設定ファイルに書かれた順で判定し、最初にマッチしたlocationを選んで終了
1. 修飾子`なし`のlocationを選んで終了  

#### root

- Syntax: root path;
- Default: root html;
- Context: http, server, location, if in location

リクエストのルートディレクトリの指定。

#### server

- Syntax: server { ... }
- Default: —
- Context: http

仮想サーバを定義するコンテキスト。

#### try_files

- Syntax:
  - try_files file ... uri;
  - try_files file ... =code;
- Default: —
- Context: server, location

指定された順序でファイルの存在を確認し、最初に見つかったファイルをリクエスト処理に使う。

#### types

- Syntax: types { ... }
- Default:
- types { text/html  html; image/gif  gif; image/jpeg jpg; }
- Context: http, server, location

ファイル名拡張子をレスポンスのMIMEタイプにマップする。

#### fastcgi_pass

- Syntax: fastcgi_pass address;
- Default: —
- Context: location, if in location

FastCGIサーバのアドレス

#### fastcgi_index

- Syntax: fastcgi_index name;
- Default: —
- Context: http, server, location

`/`で終わるURLの時の`$fastcgi_script_name`の値

#### fastcgi_param

- Syntax: fastcgi_param parameter value [if_not_empty];
- Default: —
- Context: http, server, location

FastCGIサーバに渡すパラメタータの設定  
NginxのDockerイメージの場合`/etc/nginx/fastcgi_params`に主な設定が書いてあって`/etc/nginx/conf.d/default.conf`でそれを読み込んでいる

### 主な組み込み変数

#### $args、$query_string

GETパラメータ

#### $document_root

現在のリクエストの`root`または`alias`

#### $is_args

GETパラメータがあれば`?`、なければ空文字列

#### $uri

現在のuri  
引数は含まない  
内部リダイレクトなどで変更されうるので注意

#### $request_url

リクエストされたurl  
引数も含む

### パフォーマンス関連

TODO

## DockerでNginx + PHP-FPM環境の設定

TODO

PHPのビルトインサーバはprd環境では公式で非推奨。なぜかは分からない。  
なのでApacheやNginxなどのWebサーバとセットで使うことが好ましい。  

## NginxってApacheと比べて何がいいの？

TODO

<https://aosabook.org/en/v2/nginx.html>

## trailing slash

TODO

## 内部リダイレクト

TODO
