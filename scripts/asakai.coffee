CronJob = require('cron').CronJob

rtg = require("url").parse(process.env.REDISTOGO_URL)
redis = require("redis").createClient(rtg.port, rtg.hostname)
redis.auth(rtg.auth.split(":")[1])

# for local test.
# redis = require('redis').createClient()

module.exports = (robot) ->

    robot.hear /(DB確認)/i, (msg) ->
        selectDb((lastDuty) ->
            connected = redis.get("LAST_DUTY", (err, cache) ->
                if err
                    console.log "Error: #{err}"
                else
                    console.log "successfully connected."
                    robot.send {room: "dairy_scrum"}, "#{cache}"
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

    new CronJob('25 13 * * 1-5', () ->
        message((turnOfDuty) ->
            robot.send {room: "dairy_scrum"}, "やぁ、みなさん。おはやう。\n今日の当番は#{turnOfDuty}"
            return
        )
        return
    ).start()

    new CronJob('30 13 * * 1', () ->
        robot.send {room: "sprint_planning"}, "@channel\n今週のスプリント計画の時間ではないですか。\nこれはありがたい。"
        return
    ).start()

    new CronJob('30 13 * * 2-5', () ->
        robot.send {room: "dairy_scrum"}, "@channel\nお忙しいところすみません。\nデイリースクラムの時間ですね。"
        return
    ).start()

    new CronJob('25 17 * * 5', () ->
        message((turnOfDuty) ->
            robot.send {room: "sprint_review"}, "やあ、みなさん。お疲れ様。\n今週の当番は#{turnOfDuty}"
            return
        )
        return
    ).start()

    new CronJob('30 17 * * 5', () ->
        robot.send {room: "sprint_review"}, "@channel\nうふふふふ。\nスプリントレビューの時間だよ。"
        return
    ).start()

    message = (send) ->
        members = [
            "@wataru\ ochi", "@takuto\ nagano", "@NS\ 坂本\ 大岳"
        ]

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

    upsertDb = (name) ->
        connected = redis.set("LAST_DUTY", name)
        if connected
            console.log "successfully connected."
            console.log "table upserted."
        return

    selectDb = (callback) ->
        connected = redis.get("LAST_DUTY", (err, cache) ->
            if err
                console.log "Error: #{err}"
            else
                console.log "successfully connected."
                callback(cache)
            return
        )
        return
