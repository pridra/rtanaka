# Description:
#  Slackに登録されたファイルを一括削除するためのscript
# 
# Notes:
#  Entry example
#  ファイル削除 YES 120 pass:nextscape
#  https://slack.com/api/
#
# Author:
#  wataru.ochi

request = require('request')
crypto = require("crypto");

tokenBits = [
    'xoxb-28756',
    '6369249-qm',
    '29045QAjeL',
    '5hvWMbKAh0',
    'SAjeL5hvWM',
    'bKAh0SA'
]

start_msg = '今月もお掃除をしませう！'
finished_msg = 'files お掃除終わりでせう！'
listing_finished_msg = '削除リスト取得完了でせう。'
pass_error_msg = 'ERROR: passphraseを入力してください'

days = [1..1000]

answerYes = [
    'yes',
    'YES',
    'Yes'
]

# Commands:
#  slackに存在するファイルをお掃除する
#
module.exports = (robot) ->

#    new CronJob('30 08 1 * *', () ->
#        robot.send {room: "random"}, "#{start_msg}"
#        return
#    ).start()

    robot.hear /ファイル削除/i, (msg) ->
        for answer in answerYes
            if msg.message.text.indexOf(answer) != -1
                deleteTask(msg)
                break
        return

    listRequest = (msg, pages, to, response) ->
        passphrase = pickPass(msg)
        if !passphrase
            return

        apiToken = decodeToken(passphrase)
        url = 'https://slack.com/api/files.list'
        request.get url, {
            json: true,
            qs: {
                 token: apiToken,
                 ts_to: Date.now - to * 24 * 60 * 60,
                 count: 1000,
                 page: pages,
                 exclude_archived: 1
             }
        }, response

    deleteRequest = (msg, count, id, finished) ->
        passphrase = pickPass(msg)
        if !passphrase
            return

        apiToken = decodeToken(passphrase)
        url = 'https://slack.com/api/files.delete'
        request.get url, {
            json: true,
            qs: {
                token: apiToken,
                file: id
             }
        }, (err, res, body) ->
            console.log "received delete response"
            if finished
                if msg
                    console.log "delete: #{count}#{finished_msg}"
                    robot.send {room: msg.message.user.room}, "#{count}#{finished_msg}"
                else
                    console.log "delete: #{count}#{finished_msg}"
                    robot.send {room: "random"}, "#{count}#{finished_msg}"
            parseJson(err, body)
            return

    deleteTask = (msg) ->
        d = 90
        for day in days
            if msg.message.text.indexOf(day) != -1
                d = day
            else
                # default 90 days ago
        console.log "#{d}日より古いファイルを削除します"
        robot.send {room: msg.message.user.room}, "#{d}日より古いファイルを削除します"
        listRequest(msg, 1, d, (err, res, body) ->
            console.log "received origin response"
            if err
                robot.send {room: msg.message.user.room}, "LIST REQUEST ERROR!!!: #{err}"
            json = parseJson(err, body)
            if json
                pages = json['paging']['pages']
                ids = []
                if pages > 1
                    jsonArray = []
                    count = 0
                    isAll = false
                    for i in [1..pages]
                        console.log "for page#{i}"
                        listRequest(msg, i, d, (er, re, bo) ->
                            if er
                                robot.send {room: msg.message.user.room}, "LIST REQUEST ERROR!!!: #{er}"
                            count++
                            data = parseJson(er, bo)
                            if data
                                robot.send {room: msg.message.user.room}, "削除リスト page#{data['paging']['page']}を取得しました.."
                                jsonArray.push(data)
                                for jsn in jsonArray
                                    Array.prototype.push.apply(ids, convertToIdsFromJson(jsn))
                                if count is pages
                                    robot.send {room: msg.message.user.room}, listing_finished_msg
                                    deleteFiles(msg, ids)
                            return
                        )
                else
                    if json
                        robot.send {room: msg.message.user.room}, "削除リスト page#{data['paging']['page']}を取得しました.."
                        robot.send {room: msg.message.user.room}, listing_finished_msg
                        Array.prototype.push.apply(ids, convertToIdsFromJson(json))
                        deleteFiles(msg, ids)
            return
        )
        return

    parseJson = (err, body) ->
        if err
            console.log "ERROR!!!: #{err}"
        jString = JSON.stringify(body)
#        console.log "jString: #{jString}"
        json = JSON.parse(jString)
        accept = json['ok']
        if accept
            console.log "ok: true"
            return json
        else
            throw new Error("PARSE ERROR!: #{json['error']}")
            return null

    convertToIdsFromJson = (json) ->
        ids = []
        files = json['files']
        for file, i in files
            id = file['id']
            ids.push(id)
        console.log "convert finished"
#        console.log "convert files: #{JSON.stringify(ids)}"
        return ids

    deleteFiles = (msg, ids) ->
        count = ids.length
        finished = false
        for id ,i in ids
            console.log "delte id number:#{i}, #{id}"
            finished = true if i is count - 1
            deleteRequest(msg, count, id, finished)
        return

    decodeToken = (passphrase) ->
        enc = ''
        for bit in tokenBits
            enc += bit
        decipher = crypto.createDecipher('aes-256-ctr', passphrase)
        dec = decipher.update(enc, 'base64', 'utf8')
        dec += decipher.final('utf8')
        return dec

    pickPass = (msg) ->
        key = 'pass:'
        text = msg.message.text
        index = text.indexOf(key)
        if index == -1
            robot.send {room: msg.message.user.room}, pass_error_msg
            return null
        pass = text.substring(index + key.length, msg.length)
        if !pass
            robot.send {room: msg.message.user.room}, pass_error_msg
            return null
        return pass
