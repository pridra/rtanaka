# Descriptions:
#  田中くんの勤怠を通知するscript
#
# Notes:
#  nothing
#
# Author:
#  wataru.ochi
#

# Commands:
#  田中くんの勤怠通知
#
module.exports = (robot) ->

  ## 起きた時、slack-adapterがつながるのを待って通知
  cid = setInterval ->
    return if typeof robot?.send isnt 'function'
    robot.send {room: "#hubot-test"}, "おはやう。"
    clearInterval cid
  , 1000

  ## 寝た時、通知してからexitする
  on_sigterm = ->
    robot.send {room: "#hubot-test"}, 'さやうなら。'
    setTimeout process.exit, 1000

  if process._events.SIGTERM?
    process._events.SIGTERM = on_sigterm
  else
    process.on 'SIGTERM', on_sigterm
