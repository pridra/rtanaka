#http://jugemkey.jp/api/waf/api_free.php
http = require('http')

constellations = [
  '牡羊座',
  '牡牛座',
  '双子座',
  '蟹座',
  '獅子座',
  '乙女座',
  '天秤座',
  '蠍座',
  '射手座',
  '山羊座',
  '水瓶座',
  '魚座'
]

rank = [
  "",
  "残念",
  "よくはない",
  "普通",
  "まずまず",
  "最高！"
]

module.exports = (robot) ->
  robot.hear /(占い|運勢)/i, (msg) ->
    check = ''
    index = 12
    for conste, i in constellations
      if msg.message.text.indexOf(conste) != -1
        check = conste
        index = i
    if check == ''
      return
    date = new Date()
    year = date.getFullYear()
    month = ("0" + (date.getMonth() + 1)).slice(-2)
    day = ("0" + date.getDate()).slice(-2)
    datestring = "#{year}/#{month}/#{day}"
    url = "http://api.jugemkey.jp/api/horoscope/free/#{year}/#{month}/#{day}"
    http.get url, (res) ->
      body = ''
      res.setEncoding('utf8')
      res.on 'data', (chunk) ->
        body += chunk
      res.on 'end', (res) ->
        ret = JSON.parse(body)
        data = ret["horoscope"][datestring][index]
        msg.reply "あいっ。"
        msg.send "今日(#{datestring})の *#{check}* の運勢は、\n
*#{data["content"]}*\n
ランキングは #{data["rank"]}位\n
ラッキーアイテムは #{data["item"]}\n
ラッキーカラーは #{data["color"]}\n
こんなかんじでせう。 _<原宿占い館 塔里木 より>_"
