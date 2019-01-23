# Description:
#  this script is used to scrum
#
# Notes:
#  nothing
#
# Author:
#  wataru.ochi

CronJob = require('cron').CronJob

rtg = require("url").parse(process.env.REDIS_URL)
redis = require("redis").createClient(rtg.port, rtg.hostname)
redis.auth(rtg.auth.split(":")[1])

# for local test.
# redis = require('redis').createClient()

# Commands:
#  send scrum message to slack
#
module.exports = (robot) ->

    robot.hear /(DB確認)/i, (msg) ->
        selectDb((lastDuty) ->
            connected = redis.get("LAST_DUTY", (err, cache) ->
                if err
                    console.log "check db: Error #{err}"
                else
                    console.log "check db: successfully connected."
                    robot.send {room: "hubot-test"}, "#{cache}"
                return
            )

            return
        )
        return

    robot.hear /(日直)/i, (msg) ->
        message((turnOfDuty) ->
            msg.send "あいっ。今日の日直は#{turnOfDuty}"
            return
        )
        return

    robot.hear /(次いこう)/i, (msg) ->
        message((turnOfDuty) ->
            msg.send "あいっ。じゃあ#{turnOfDuty}"
            return
        )
        return

    new CronJob('30 09 * * 1-5', () ->
        message((turnOfDuty) ->
            robot.send {room: "pj-frima-scrum"}, "やぁ、みなさん。おはやう。\n今日の当番は#{turnOfDuty}"
            return
        )
        return
    ).start()

    new CronJob('00 11 * * 2', () ->
        robot.send {room: "pj-frima-scrum"}, "@frima\n今週のスプリント計画の時間ではないですか。"
        return
    ).start()

    new CronJob('30 10 * * 1-5', () ->
        robot.send {room: "pj-frima-scrum"}, "@frima\nお忙しいところすみません。\nデイリースクラムの時間ですね。"
        return
    ).start()

#    new CronJob('25 17 * * 5', () ->
#        message((turnOfDuty) ->
#            robot.send {room: "pj-frima-scrum"}, "やあ、みなさん。お疲れ様。\n今週の当番は#{turnOfDuty}"
#            return
#        )
#        return
#    ).start()

#    new CronJob('30 17 * * 5', () ->
#        robot.send {room: "pj-frima-scrum"}, "@frima\nうふふふふ。\nスプリントレビューの時間だよ。"
#        return
#    ).start()

    message = (send) ->
        # UBHAXJD8V:前田, U1X8UV12N:山城, UBG88U4SW:杉本, UBH3JT7V1:島内, U9XV9BZCK:山田,
        # UBJ7T59V5:後藤, UBLLAS3SQ:野々下, UF847TJ7K:川上, UFA4E2E86:越智, UCLUECR5M:武田, U9TAHG70A:西
        members = ["@UBHAXJD8V", "@U1X8UV12N", "@UBG88U4SW", "@UBH3JT7V1", "@U9XV9BZCK","@UBJ7T59V5", \
                   "@UBLLAS3SQ", "@UF847TJ7K", "@UFA4E2E86", "@UCLUECR5M", "@U9TAHG70A"]
        selectDb((lastDuty) ->
             member = ""
             loop
                 index = Math.floor(Math.random() * members.length)
                 member = members[index]
                 if member isnt lastDuty
                     upsertDb(member)
                     break
             send(" #{member} なのです。")
             return
        )
        return

# slack上のメンバーが多く、その他のチームで追加や削除がある場合はリスト取得よりも決め打ちの方がやりやすいため一旦コメントアウト
#        request = require('request')
#        request.get
#            url: "https://slack.com/api/users.list?token=#{process.env.HUBOT_SLACK_TOKEN}", (err, response, body) ->
#                members = (member_raw["name"] \
#
#                for member_raw in JSON.parse(body)["members"] when \
#                   !member_raw["is_bot"] && \
#                    member_raw["id"] != "UBHAXJD8V" && member_raw["id"] != "U1X8UV12N" && \
#                    member_raw["id"] != "UBG88U4SW" && member_raw["id"] != "UBH3JT7V1" && \
#                    member_raw["id"] != "U9XV9BZCK" && member_raw["id"] != "UBJ7T59V5" && \
#                    member_raw["id"] != "UFA4E2E86" && member_raw["id"] != "UCLUECR5M" && \
#                    member_raw["id"] != "U9TAHG70A")
#                selectDb((lastDuty) ->
#                    member = ""
#                    loop
#                        index = Math.floor(Math.random() * members.length)
#                        member = members[index]
#                        if member isnt lastDuty
#                            upsertDb(member)
#                            break
#                    send(" @#{member} なのです。")
#                    return
#                )
#                return
#        return

    upsertDb = (name) ->
        connected = redis.set("LAST_DUTY", name)
        if connected
            console.log "upsertDb: successfully connected."
            console.log "table upserted."
        else
            console.log "upsertDb: Error"
        return

    selectDb = (callback) ->
        connected = redis.get("LAST_DUTY", (err, cache) ->
            if err
                console.log "selectDb: Error #{err}"
            else
                console.log "selectDb: successfully connected."
                callback(cache)
            return
        )
        return
