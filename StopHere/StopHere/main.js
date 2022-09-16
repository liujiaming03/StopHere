
var new_version = "1.8"
var newVersionAddress = "https://www.pgyer.com/Uvaj"

require('StopHere.AppDelegate')
defineClass('StopHere.AppDelegate', {
    checkVersion:function () {
        return new_version
    }
})

defineClass('StopHere.AppDelegate', {
    newVersionAddress:function () {
        return newVersionAddress
    }
})
