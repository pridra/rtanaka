#http://weather.livedoor.com/weather_hacks/webservice
http = require('http')

module.exports = (robot) ->
  robot.hear /天気/i, (msg) ->
    city = '130010'
    url = 'http://weather.livedoor.com/forecast/webservice/json/v1?city=' + city
    http.get url, (res) ->
      body = ''
      res.setEncoding('utf8')
      res.on 'data', (chunk) ->
        body += chunk
      res.on 'end', (res) ->
        ret = JSON.parse(body)
        msg.send "あいっ。"
        msg.send ret['forecasts'][0]['dateLabel'] + '（' + ret['forecasts'][0]['date'] + '）'
        if ret['forecasts'][0]['temperature']['max'] != null
          msg.send '最高気温: ' + ret['forecasts'][0]['temperature']['max']['celsius']
        if ret['forecasts'][0]['temperature']['min'] != null
          msg.send '最低気温: ' + ret['forecasts'][0]['temperature']['min']['celsius']
        msg.send ret['forecasts'][0]['telop']
        msg.send ret['forecasts'][0]['image']['url']
        msg.send "```\n" + ret['description']['text'] + "\n```"
