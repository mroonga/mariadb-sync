# MariaDBとmroongaを最新版にするスクリプト

このリポジトリではMariaDBとmroongaを最新版にするスクリプトを提供してい
ます。それがsync.shです。これを実行すると以下のことを自動でやってくれま
す。

  * リポジトリの取得
  * MariaDBのtrunkから最新の変更をマージ
  * 最新のgroonga/groonga-normalizer-mysql/mroongaをマージ
  * BUILD/compile-amd64-valgrind-maxでビルドしてテスト実行

ただし、launchpadのリポジトリへのpushはしません。↑のテスト実行結果を確
認して、問題なければ以下のコマンドを使ってpushしてください。

    % bzr push --overwrite lp:~mroonga/maria/mroonga

## 使い方

最初だけ実行することがあります。以下の作業です。この作業は2回目以降は必
要ありません。

    % mkdir -p ~/work/maria
    % cd ~/work/maria
    % git clone git@github.com:mroonga/mariadb-sync.git

以下は毎回実行する作業です。

    % cd ~/work/maria/mariadb-sync
    % ./sync.sh
    （↑の結果を確認し、問題がなかったら↓を実行。）
    % bzr push --overwrite lp:~mroonga/maria/mroonga

最初にsync.shを実行したときはMariaDBのリポジトリを `bzr branch` してく
るのでとても時間がかかります。（数時間単位）
