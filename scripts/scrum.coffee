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

    robot.hear /(select reviewer)/i, (msg) ->
        messageRV(msg, (turnOfDuty) ->
            msg.send "あいっ。次のレビュワーは#{turnOfDuty}"
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

    new CronJob('00 11 * * 1', () ->
        robot.send {room: "pj-frima-scrum"}, "@frima\n今週のスプリント計画の時間ではないですか。"
        return
    ).start()

    new CronJob('30 10 * * 1-5', () ->
        robot.send {room: "pj-frima-scrum"}, "@frima\nお忙しいところすみません。\nデイリースクラムの時間ですね。"
        return
    ).start()

    # 日直選定メッセージを作成します
    message = (send) ->
        request = require('request')
        request.get
            url: "https://slack.com/api/users.list?token=#{process.env.HUBOT_SLACK_TOKEN}", (err, response, body) ->
                
                # UBHAXJD8V:前田, U1X8UV12N:山城, UBG88U4SW:杉本, UBH3JT7V1:島内, U9XV9BZCK:山田,
                # UBJ7T59V5:後藤, UBLLAS3SQ:野々下, UF847TJ7K:川上, UFA4E2E86:越智
                mem1 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBHAXJD8V")
                mem2 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "U1X8UV12N")
                mem3 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBG88U4SW")
                mem4 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBH3JT7V1")
                mem5 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "U9XV9BZCK")
                mem6 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBJ7T59V5")
                mem7 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBLLAS3SQ")
                mem8 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UF847TJ7K")
                mem9 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UFA4E2E86")
                members = [mem1, mem2, mem3, mem4, mem5, mem6, mem7, mem8, mem9]

                console.log "members: #{members}"
                selectDb((lastDuty) ->
                     member = ""
                     loop
                         index = Math.floor(Math.random() * members.length)
                         member = members[index]
                         if member isnt lastDuty
                             upsertDb(member)
                             break
                     send(" @#{member} なのです。")
                     return
                )
                return

    # レビュワー選定メッセージを作成します
    messageRV = (msg, send) ->
        request = require('request')
        request.get
            url: "https://slack.com/api/users.list?token=#{process.env.HUBOT_SLACK_TOKEN}", (err, response, body) ->
                
                # UBHAXJD8V:前田, UBG88U4SW:杉本, UBH3JT7V1:島内, U9XV9BZCK:山田, UBJ7T59V5:後藤, UBLLAS3SQ:野々下
                mem1 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBHAXJD8V")
                mem2 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBG88U4SW")
                mem3 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBH3JT7V1")
                mem4 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "U9XV9BZCK")
                mem5 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBJ7T59V5")
                mem6 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBLLAS3SQ")
                members = [mem1, mem2, mem3, mem4, mem5, mem6]

                console.log "sender: #{msg.message.user.id}"
                console.log "members: #{members}"
                selectRVDb((lastDuty) ->
                     sender = msg.message.user.id
                     member = ""
                     loop
                         index = Math.floor(Math.random() * members.length)
                         member = members[index]
                         if sender isnt member and member isnt lastDuty
                             upsertRVDb(member)
                             break
                     send(" @#{member} なのです。")
                     return
                )


    # redisに日直を保存（更新）する
    upsertDb = (name) ->
        connected = redis.set("LAST_DUTY", name)
        if connected
            console.log "upsertDb: successfully connected."
            console.log "table upserted."
        else
            console.log "upsertDb: Error"
        return

    # 日直をredisから取り出して返す
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

    # redisにレビュワーを保存（更新）する
    upsertRVDb = (name) ->
        connected = redis.set("LAST_DUTY_RV", name)
        if connected
            console.log "upsertRVDb: successfully connected."
            console.log "table upserted."
        else
            console.log "upsertRVDb: Error"
        return

    # レビュワーをredisから取り出して返す
    selectRVDb = (callback) ->
        connected = redis.get("LAST_DUTY_RV", (err, cache) ->
            if err
                console.log "selectRVDb: Error #{err}"
            else
                console.log "selectRVDb: successfully connected."
                callback(cache)
            return
        )
        return
