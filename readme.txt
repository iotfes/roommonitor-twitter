#----------------------------------------------------------------------
# checkRoomTweet_c8y.rb
# ver.1.0
# 2017/01/19
# Cumulocity APIを用いて下記3センサから情報を取得して会議室の利用状況を解析し、解析結果をTwitterに投稿するプログラム。
# - DHT11温湿度センサ
# - TSL2561照度センサ
# - Roboba043赤外線アレイセンサ
#----------------------------------------------------------------------
○前提
- Raspberry piにCumulocity Agentをインストールしており、正常に接続していること。
-- http://www.cumulocity.com/guides/devices/raspberry-pi/

- 下記3センサがRaspberry piに接続されており、Cumulocityにデータをアップロードしていること。
-- DHT11温湿度センサ
--- https://github.com/iotfes/dht11-sensor
-- TSL2561照度センサ
--- https://github.com/iotfes/tsl2561-sensor
-- Roboba043赤外線アレイセンサ
--- https://github.com/iotfes/roboba043-sensor

- Raspberry piのAdministrationアプリの"Own applications" -> "Create application"よりアプリケーション情報を登録し、App-Keyを取得していること。(App-Key登録画面例.png参照)
- Twitterアカウントを所有しており、下記の値を取得していること。
-- consumer_key
-- consumer_secret
-- access_token
-- access_token_secret
-- 詳細は下記を参照：http://hello-apis.blogspot.jp/2013/03/twitterapi.html

○セットアップ
- Twitter用Rubyライブラリをインストール
$ sudo gem install twitter

○動作例
sho-pc:cumulocity sho$ ruby chechRoomTweet_c8y.rb
https://nttcom.cumulocity.com/measurement/measurements?dateFrom=2017-01-19&dateTo=2017-01-20&type=c8y_dht11&revert=true&pageSize=1
https://nttcom.cumulocity.com/measurement/measurements?dateFrom=2017-01-19&dateTo=2017-01-20&type=c8y_tsl2561&revert=true&pageSize=1
https://nttcom.cumulocity.com/measurement/measurements?dateFrom=2017-01-19&dateTo=2017-01-20&type=c8y_roboba043&revert=true&pageSize=1
*** area [1, 4] is higher than 26.0℃ , but Don't Care. ***
*** area [1, 5] is higher than 26.0℃ . ***
*** area [2, 0] is higher than 26.0℃ . ***
*** area [2, 1] is higher than 26.0℃ . ***
*** area [2, 2] is higher than 26.0℃ . ***
*** area [2, 4] is higher than 26.0℃ . ***
*** area [2, 5] is higher than 26.0℃ . ***
*** area [3, 0] is higher than 26.0℃ . ***
*** area [3, 1] is higher than 26.0℃ . ***
*** area [3, 2] is higher than 26.0℃ . ***
*** area [3, 3] is higher than 26.0℃ . ***
*** area [3, 4] is higher than 26.0℃ . ***
*** area [3, 5] is higher than 26.0℃ . ***
*** area [3, 6] is higher than 26.0℃ . ***
*** area [4, 0] is higher than 26.0℃ . ***
*** area [4, 1] is higher than 26.0℃ . ***
*** area [4, 2] is higher than 26.0℃ . ***
*** area [4, 3] is higher than 26.0℃ . ***
*** area [4, 4] is higher than 26.0℃ . ***
*** area [4, 5] is higher than 26.0℃ . ***
*** area [4, 6] is higher than 26.0℃ . ***
*** area [4, 7] is higher than 26.0℃ . ***
*** area [5, 0] is higher than 26.0℃ . ***
*** area [5, 1] is higher than 26.0℃ . ***
*** area [5, 2] is higher than 26.0℃ . ***
*** area [5, 3] is higher than 26.0℃ . ***
*** area [5, 4] is higher than 26.0℃ . ***
*** area [5, 5] is higher than 26.0℃ . ***
*** area [5, 6] is higher than 26.0℃ . ***
*** area [5, 7] is higher than 26.0℃ . ***
*** area [6, 0] is higher than 26.0℃ . ***
*** area [6, 1] is higher than 26.0℃ . ***
*** area [6, 2] is higher than 26.0℃ . ***
*** area [6, 3] is higher than 26.0℃ . ***
*** area [6, 4] is higher than 26.0℃ . ***
*** area [6, 5] is higher than 26.0℃ . ***
*** area [6, 6] is higher than 26.0℃ . ***
*** area [6, 7] is higher than 26.0℃ . ***
*** area [7, 0] is higher than 26.0℃ , but Don't Care. ***
*** area [7, 1] is higher than 26.0℃ . ***
*** area [7, 2] is higher than 26.0℃ . ***
*** area [7, 3] is higher than 26.0℃ . ***
*** area [7, 4] is higher than 26.0℃ . ***
*** area [7, 5] is higher than 26.0℃ . ***
*** area [7, 6] is higher than 26.0℃ . ***
*** area [7, 7] is higher than 26.0℃ . ***
---------------------- Reports --------------------------
- 8x8 temperature matrix: 
[25.0, 24.5, 25.75, 24.5, 26.0, 25.75, 26.0, 25.0]
[26.0, 25.75, 25.0, 24.25, 27.0, 26.5, 24.5, 26.0]
[26.5, 26.25, 26.5, 25.75, 27.0, 26.75, 25.75, 25.5]
[27.0, 28.25, 28.25, 29.5, 31.5, 29.25, 27.25, 25.5]
[28.0, 29.25, 27.5, 28.75, 29.75, 29.0, 27.0, 27.25]
[28.5, 29.75, 27.75, 28.0, 28.25, 28.25, 27.5, 28.75]
[27.75, 27.5, 27.5, 26.5, 28.5, 27.75, 27.25, 26.75]
[26.5, 26.25, 26.5, 27.25, 29.0, 29.25, 26.5, 29.0]
- Higher Temperature Area: 
-- temperatureThreshold: 26.0
-- Don't Care Area: 
[[0, 0], [7, 0], [1, 4]]
[0, 0, 0, 0, 0, 0, 0, 0]
[0, 0, 0, 0, 1, 1, 0, 0]
[1, 1, 1, 0, 1, 1, 0, 0]
[1, 1, 1, 1, 1, 1, 1, 0]
[1, 1, 1, 1, 1, 1, 1, 1]
[1, 1, 1, 1, 1, 1, 1, 1]
[1, 1, 1, 1, 1, 1, 1, 1]
[1, 1, 1, 1, 1, 1, 1, 1]
- sum: 44
- DI: 66.5884
- status: 101
- tweetStr: [Cumulocity] 会議室Cは使用中です。--- 温度: 22.0℃, 湿度: 33.0%, 照度: 2064.35ルクス, 不快指数: 66 (快い) (2017年01月19日 17:00:14現在)。
---------------------------------------------------------
Twitterへ投稿しました。

