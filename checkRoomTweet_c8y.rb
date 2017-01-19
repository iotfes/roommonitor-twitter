# coding: utf-8
#----------------------------------------------------------------------
# checkRoomTweet_c8y.rb
# ver.1.0
# 2017/01/19
# Cumulocity APIを用いて下記3センサから情報を取得して会議室の利用状況を解析し、解析結果をTwitterに投稿するプログラム。
# - DHT11温湿度センサ
# - TSL2561照度センサ
# - Roboba043赤外線アレイセンサ
#----------------------------------------------------------------------
# coding: utf-8
$LOAD_PATH.push('.')
require 'twitter'
require 'yaml'
require 'net/https'
require 'time'
require 'json'
require "http_lib"
#----------------------------------------------------------------------
#                          Pre-defined
#----------------------------------------------------------------------
# 会議室の状態
OCCUPIED   = 0x01   # 使用中
FREE       = 0x02   # 空き
LIGHTS_ON  = 0x04   # 照明点灯
#DEVICES_ON = 0x08   # ディスプレイ点灯(未使用)
#----------------------------------------------------------------------
#                           Method
#----------------------------------------------------------------------
# 除外エリアかどうかを判定するメソッド(devArrayと比較する)
def isDevice(array, point)
  result = FALSE
  for num in 0..(array.size - 1) do
    #puts "array[#{num}]: #{array[num]}, point: #{point}"
    if array[num] == point then
      result = TRUE
    end
  end
  return result
end
# 不快指数に応じた文字列を生成するメソッド
def createDiscomfortString(discomfortIndex)
  if discomfortIndex < 55 then
    str =  "(寒い)"
  elsif discomfortIndex < 60 then
    str =  "(肌寒い)"
  elsif discomfortIndex < 65 then
    str =  "(何も感じない)"
  elsif discomfortIndex < 70 then
    str =  "(快い)"
  elsif discomfortIndex < 75 then
    str =  "(暑くない)"
  elsif discomfortIndex < 80 then
    str =  "(やや暑い)"
  elsif discomfortIndex < 85 then
    str =  "(暑くて汗が出る)"
  else
    str =  "(暑くてたまらない)"
  end
  returnStr = "不快指数: #{discomfortIndex.floor} #{str}"
  return returnStr
end
#----------------------------------------------------------------------
#                          設定ファイル読み込み
#----------------------------------------------------------------------
confFileName = "./config.yml"
config = YAML.load_file(confFileName)
# 温度閾値の差分(温湿度センサが取得した温度との差分)
TEMPERATURE_DIFF = config["temperature_diff"]
# 照度閾値
LUMINOSITY = config["luminosity"]
# 会議室名
ROOMNAME = config["room_name"]
# 赤外線アレイセンサのマトリクスにおける、室内のデジタル機器の位置(v2から対応)
devArray = config["location_devices"]

# Twitterアカウント情報
client = Twitter::REST::Client.new(
  consumer_key:        config["twitter"]["consumer_key"],
  consumer_secret:     config["twitter"]["consumer_secret"],
  access_token:        config["twitter"]["access_token"],
  access_token_secret: config["twitter"]["access_token_secret"]
)
# Cumulocity API情報
host = config["c8y"]["host"]
keys = {
  username: config["c8y"]["username"],
  password: config["c8y"]["password"],
  appkey: config["c8y"]["appkey"]
}
# typeを指定
dht11Type = config["c8y"]["dht11Type"]
tsl2561Type = config["c8y"]["tsl2561Type"]
roboba043Type = config["c8y"]["roboba043Type"]

# fragmentTypeを指定
dht11FragmentType = config["c8y"]["dht11FragmentType"]
tsl2561FragmentType = config["c8y"]["tsl2561FragmentType"]
roboba043FragmentType = config["c8y"]["roboba043FragmentType"]

#----------------------------------------------------------------------
#                            メイン処理
#----------------------------------------------------------------------
begin
      
  #------ Cumulocityから温湿度センサのデータを取得 ------
  uri = "/measurement/measurements"
  result = getLatestData(host, uri, keys, dht11Type)
  # エラーチェック(DHT11)
  if result["measurements"] == nil then
    puts result
    raise "error in DHT11"
  end
  
  # 温度と湿度を取得
  currentTemperature = result["measurements"][0]["#{dht11FragmentType}"]["temperature"]["value"]
  currentHumidity = result["measurements"][0]["#{dht11FragmentType}"]["humidity"]["value"]
  
  #------ Cumulocityから照度センサのデータを取得 ------
  uri = "/measurement/measurements"
  result = getLatestData(host, uri, keys, tsl2561Type)
  # エラーチェック(TSL2561)
  if result["measurements"] == nil then
    puts result
    raise "error in TSL2561"
  end
  
  # 照度を取得
  currentLuminosity = result["measurements"][0]["#{tsl2561FragmentType}"]["luminosity"]["value"]
  
  #------ Cumulocityから赤外線アレイセンサのデータを取得 ------
  uri = "/measurement/measurements"
  result = getLatestData(host, uri, keys, roboba043Type)
  # エラーチェック(Roboba043)
  if result["measurements"] == nil then
    puts result
    raise "error in Roboba043"
  end
  
  # 温度64個を取得
  measureTime = Time.strptime(result["measurements"][0]["time"], "%Y-%m-%dT%H:%M:%S").strftime("%Y年%m月%d日 %H:%M:%S")
  temperatureMatrix = Array.new(8).map{Array.new(8,0)}
  counter = 0
  for i in 0..7 do
    for j in 0..7 do
      index = "temperature" + counter.to_s
      temperatureMatrix[i][j] = result["measurements"][0]["#{roboba043FragmentType}"]["#{index}"]["value"].to_f
      counter = counter + 1
    end
  end
  
  # 閾値より高温のエリアを記録するための8x8二次元配列
  judgeMatrix = Array.new(8).map{Array.new(8,0)}
  
  # 現在の温度を温度閾値に反映させる
  temperatureThreshold = currentTemperature + TEMPERATURE_DIFF
  
  # 閾値より高温のエリアを記録
  for i in 0..7 do
    for j in 0..7 do
      
      # 現在位置[i, j]を設定
      location = [i, j]    
      
      if temperatureMatrix[i][j] > temperatureThreshold then
        # 結果表示用文字列作成
        if isDevice(devArray, location) == FALSE then
          extraStr = ""
        else
          extraStr = ", but Don't Care"
        end
        # [i,j]の温度が閾値より高い場合、judgeMatrixに記録する。
        judgeMatrix[i][j] = 1
        # 高温エリア情報を表示
        puts "*** area [#{i}, #{j}] is higher than #{temperatureThreshold}℃ #{extraStr}. ***"
      end
    end
  end

  # 高温エリアを解析
  sum = 0
  for i in 0..7 do
    for j in 0..7 do
      location = [i, j]
      if isDevice(devArray, location) == FALSE then
        # デバイスエリア以外が高温である場合、sumを1加算する
        sum += judgeMatrix[i][j].to_i
      end
    end
  end
  
  # 会議室の状態を示す変数を初期化
  status     = 0x00
  
  # 照明の使用状況を判定
  if currentLuminosity > LUMINOSITY then
    status |= LIGHTS_ON
  end
  # 会議室の使用状況を判定
  if (sum > 0) && (status & LIGHTS_ON) != 0 then
    # 使用中
    status |= OCCUPIED
  else
    # 空室
    status |= FREE
  end
  
  # ツイートする文字列を設定
  if (status & OCCUPIED) != 0 then
    baseStr = "[Cumulocity] #{ROOMNAME}は使用中です。"
  elsif (status & FREE) != 0 then
    baseStr = "[Cumulocity] #{ROOMNAME}は空いています。"
  end
  
  # 追加文字列を設定(消灯し忘れ)
  if ((status & FREE) != 0) && ((status & LIGHTS_ON) != 0) then
    baseStr << "消灯し忘れています。"
  end
  
  # 不快指数を計算
  discomfortIndex = 0.81 * currentTemperature + 0.01 * currentHumidity * (0.99 * currentTemperature - 14.3) + 46.3
  # 追加文字列を設定(不快指数)
  diStr = createDiscomfortString(discomfortIndex)
  
  # 測定時刻と各種センサのデータを付加
  baseStr << "--- 温度: #{currentTemperature}℃, 湿度: #{currentHumidity}%, 照度: #{currentLuminosity}ルクス, #{diStr} (#{measureTime}現在)。"
  
  # ツイートする文字列を設定
  tweetStr = baseStr
  
  # 各種結果出力
  puts "---------------------- Reports --------------------------"
  puts "- 8x8 temperature matrix: "
  for i in 0..7 do
    p temperatureMatrix[i]
  end
  puts "- Higher Temperature Area: "
  puts "-- temperatureThreshold: #{temperatureThreshold}"
  puts "-- Don't Care Area: "
  p devArray
  for i in 0..7 do
    p judgeMatrix[i]
  end
  puts "- sum: #{sum}"
  puts "- DI: #{discomfortIndex}"
  puts "- status: #{status.to_s(2)}"
  puts "- tweetStr: #{tweetStr}"
  puts "---------------------------------------------------------"
  
  # Twitterへ投稿
  client.update(tweetStr)
  puts "Twitterへ投稿しました。"# coding: utf-8

rescue => e
  puts e.message
  exit
end
