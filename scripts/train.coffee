# Descriptions:
#  電車の遅延情報をお知らせするscript
#
# Notes:
#  http://transit.yahoo.co.jp/traininfo/area/4/
#
# Author:
#  wataru.ochi
#

client = require('cheerio-httpcli')

train_url = "http://transit.yahoo.co.jp/traininfo/area/4/"

table = []
datetext = ""

# Commands:
#  電車の遅延情報をお知らせする
#
module.exports = (robot) ->
  robot.hear /(遅延)/i, (msg) ->
    table = []
    msg.reply("あいっ。")
    client.fetch(train_url)
    .then (result) ->
      $ = result.$
      datetext = $(".subText").text()
      $("#mdStatusTroubleLine").children(".elmTblLstLine").children("table").children("tr").each (idx) ->
        table[idx] = []
        $(this).children().each (s_index) ->
          table[idx][s_index] = $(this).text()
    .then ->
      msg.send("こんなんでましたけど。（#{datetext}）")
      for row, index in table
        if index > 1
          msg.send("*#{row[0]} :* #{row[1]} : #{row[2]}")
      msg.send(train_url)
