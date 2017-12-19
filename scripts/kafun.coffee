client = require('cheerio-httpcli')

kafun_url = "http://weather.goo.ne.jp/pollen/p0018.html"

module.exports = (robot) ->
  robot.hear /(花粉)/i, (msg) ->
    table = []
    msg.reply("あいっ、へっ、へっくち。")
    client.fetch(kafun_url)
    .then (result) ->
      $ = result.$
      $("table.t01").children("tr").children("th").each (idx) ->
        if idx == 0
          msg.send($(this).text())
      $("table.t01").children("tr").children("td").each (idx) ->
        if idx == 0
          img_path = $(this).children("img").attr("pagespeed_lazy_src")
          if img_path == undefined
            img_path = $(this).children("img").attr("src").split('//<')[0]
          msg.send("http:" + img_path + $(this).text())
    .then ->
      msg.send("こんなんでましたけど。あ、ダイオードが、あぁ。")
      msg.send(kafun_url)
