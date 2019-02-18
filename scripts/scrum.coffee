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

    robot.hear /(レビューランキング)/i, (msg) ->
        selectRankingDb((callback) ->
            if callback?
                res = JSON.parse(callback)
                max = 0
                first = ''
                for member in res
                    console.log "#{member.name}さん #{member.count}回"
                    if member.count > max
                        max = member.count
                        first = member.name
                msg.send "あいっ。ランキング１位は#{max}回で#{first}さんですっ。"
            else
                msg.send "あいっ。まだ選んでないかも。"
        )
        return

    robot.hear /(ランキングクリア)/i, (msg) ->
        deleteRankingDb()
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
            robot.send {room: "pj-frima-rtanaka"}, "やぁ、みなさん。おはやう。\n今日の当番は#{turnOfDuty}"
            return
        )
        return
    ).start()

    new CronJob('00 11 * * 1', () ->
        robot.send {room: "pj-frima-rtanaka"}, "@frima\n今週のスプリント計画の時間ではないですか。"
        return
    ).start()

    new CronJob('30 10 * * 1-5', () ->
        robot.send {room: "pj-frima-rtanaka"}, "@frima\nお忙しいところすみません。\nデイリースクラムの時間ですね。"
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
#                mem4 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "U9XV9BZCK")
                mem5 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBJ7T59V5")
                mem6 = (mem["name"] for mem in JSON.parse(body)["members"] when mem["id"] == "UBLLAS3SQ")
#                members = [mem1, mem2, mem3, mem4, mem5, mem6]
                members = [mem1, mem2, mem3, mem5, mem6]

                selectRVDb((lastDuty) ->
                     sender = msg.message.user.name
                     member = ""
                     loop
                         index = Math.floor(Math.random() * members.length)
                         member = members[index]
                         if "#{sender}" isnt "#{member}" and "#{member}" isnt "#{lastDuty}"
                             upsertRankingDb(member)
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

    # レビュワー当せん回数を保存します
    upsertRankingDb = (name) ->
         selectRankingDb((value) ->
             if value?
                 # 追加して上書き
                 flag = false
                 res = JSON.parse(value)
                 for n, i in res
                     if n.name is name
                         res.splice(i, 1, { name: "#{n.name}", count: n.count+1 })
                         connected = redis.set("RV_COUNT", JSON.stringify(res))
                         if connected
                             console.log "upsertRankingDb: successfully connected."
                             console.log "table upserted."
                             flag = true
                         else
                             console.log "upsertRankingDb: Error"
                         break
                 unless flag
                     res.push({ name: "#{name}", count: 1 })
                     connected = redis.set("RV_COUNT", JSON.stringify(res))
                     if connected
                         console.log "upsertRankingDb: successfully connected."
                         console.log "table upserted."
                     else
                         console.log "upsertRankingDb: Error"
             else
                 # 初回保存
                 connected = redis.set("RV_COUNT", JSON.stringify([{ name: "#{name}", count: 1 }]))
                 if connected
                     console.log "upsertRankingDb: successfully connected."
                     console.log "table upserted."
                 else
                     console.log "upsertRankingDb: Error"
         )
         return
 
    # レビュワー当せん回数をredisから取り出して返す
    selectRankingDb = (callback) ->
        connected = redis.get("RV_COUNT", (err, cache) ->
            if err
                console.log "selectRankingDb: Error #{err}"
            else
                console.log "selectRankingDb: successfully connected."
                callback(cache)
            return
        )
        return

    # レビュワー当せん回数をクリアする
    deleteRankingDb = () ->
        connected = redis.del("RV_COUNT")
        if connected
            console.log "ranking key deleted."
        else
            console.log "ranking db failed connecetd error."
        return
