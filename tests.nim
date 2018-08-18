import std / [times, unittest]
import systimes

test "utc":
    let stime = initSysTime(05, mJan, 2000, 01, 02, 03, 04, utc())
    check stime.monthday == 5
    check stime.month == mJan
    check stime.year == 2000
    check stime.hour == 1
    check stime.minute == 2
    check stime.second == 3
    check stime.nanosecond == 4
    check stime.timezone == utc()
    check stime.utcOffset == 0
    check stime.isDst == false
    check stime.yearday == 4
    check stime.weekday == dWed

# This test is wildly non-deterministic, but it's probably ok.
test "local time":
    let dtime = now()
    let stime = toSysTime(dtime)
    check stime.monthday == dtime.monthday
    check stime.month == dtime.month
    check stime.year == dtime.year
    check stime.hour == dtime.hour
    check stime.minute == dtime.minute
    check stime.second == dtime.second
    check stime.nanosecond == dtime.nanosecond
    check stime.timezone == dtime.timezone
    check stime.utcOffset == dtime.utcOffset
    check stime.isDst == dtime.isDst
    check stime.timezone == dtime.timezone
    check stime.yearday == dtime.yearday
    check stime.weekday == dtime.weekday
    check toTime(stime) == toTime(dtime)
    check toDateTime(stime) == dtime
    check between(stime, stime + 4.days) == between(dtime, dtime + 4.days)

let s = sysnow()
