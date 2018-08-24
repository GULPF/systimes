import std / [times, math]

type
    SysTime* = object ## Represents a point-in-time with
                      ## an attached timezone.
        time: Time
        timezone: Timezone

proc timezone*(stime: SysTime): Timezone =
    ## Returns the attached timezone.
    stime.timezone

# Copied from times.nim
proc toEpochDay(monthday: MonthdayRange, month: Month, year: int): int64 =
    ## Get the epoch day from a year/month/day date.
    ## The epoch day is the number of days since 1970/01/01 (it might be negative).
    # Based on http://howardhinnant.github.io/date_algorithms.html
    var (y, m, d) = (year, ord(month), monthday.int)
    if m <= 2:
        y.dec

    let era = (if y >= 0: y else: y-399) div 400
    let yoe = y - era * 400
    let doy = (153 * (m + (if m > 2: -3 else: 9)) + 2) div 5 + d-1
    let doe = yoe * 365 + yoe div 4 - yoe div 100 + doy
    return era * 146097 + doe - 719468

# Copied from times.nim
proc fromEpochDay(epochday: int64):
        tuple[monthday: MonthdayRange, month: Month, year: int] =
    ## Get the year/month/day date from a epoch day.
    ## The epoch day is the number of days since 1970/01/01 (it might be negative).
    # Based on http://howardhinnant.github.io/date_algorithms.html
    var z = epochday
    z.inc 719468
    let era = (if z >= 0: z else: z - 146096) div 146097
    let doe = z - era * 146097
    let yoe = (doe - doe div 1460 + doe div 36524 - doe div 146096) div 365
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe div 4 - yoe div 100)
    let mp = (5 * doy + 2) div 153
    let d = doy - (153 * mp + 2) div 5 + 1
    let m = mp + (if mp < 10: 3 else: -9)
    return (d.MonthdayRange, m.Month, (y + ord(m <= 2)).int)

# Copied from times.nim
proc toAdjTime(dt: DateTime): Time =
    let epochDay = toEpochday(dt.monthday, dt.month, dt.year)
    var seconds = convert(Days, Seconds, epochDay)
    seconds.inc dt.hour * 60 * 60
    seconds.inc dt.minute * 60
    seconds.inc dt.second
    result = initTime(seconds, dt.nanosecond)

# Copied from times.nim
proc isStaticInterval(interval: TimeInterval): bool =
    interval.years == 0 and interval.months == 0 and
        interval.days == 0 and interval.weeks == 0

# Copied from times.nim
proc evaluateStaticInterval(interval: TimeInterval): Duration =
    assert interval.isStaticInterval
    initDuration(nanoseconds = interval.nanoseconds,
        microseconds = interval.microseconds,
        milliseconds = interval.milliseconds,
        seconds = interval.seconds,
        minutes = interval.minutes,
        hours = interval.hours)

# Copied from times.nim (but with different signature)
proc getDayOfWeek(unixTime: int64): WeekDay =
    # 1970-01-01 is a Thursday, we adjust to the previous Monday
    let day = floorDiv(unixTime, convert(Days, Seconds, 1)) - 3
    let weeks = floorDiv(day, 7)
    let wd = day - weeks * 7
    # The value of d is 0 for a Sunday, 1 for a Monday, 2 for a Tuesday, etc.
    # so we must correct for the WeekDay type.
    result = if wd == 0: dSun else: WeekDay(wd - 1)

proc initSysTime*(time: Time, zone: Timezone): SysTime =
    SysTime(time: time, timezone: zone)

proc initSysTime*(monthday: MonthdayRange, month: Month, year: int,
        hour: HourRange, minute: MinuteRange, second: SecondRange,
        nanosecond: NanosecondRange, zone = local()): SysTime =
    let dt = DateTime(
        monthday: monthday,
        year: year,
        month: month,
        hour: hour,
        minute: minute,
        second: second,
        nanosecond: nanosecond
    )
    let zt = zone.zonedTimeFromAdjTime(dt.toAdjTime)
    result = SysTime(time: zt.time, timezone: zone)

proc initSysTime*(monthday: MonthdayRange, month: Month, year: int,
        hour: HourRange, minute: MinuteRange, second: SecondRange,
        zone = local()): SysTime =
    initSysTime(monthday, month, year, hour, minute, second, 0, zone)

proc inZone*(stime: SysTime, zone: Timezone): SysTime =
    ## Swap timezone to ``zone``.
    SysTime(time: stime.time, timezone: zone)

proc toTime*(stime: SysTime): Time =
    ## Convert ``SysTime`` to ``Time``.
    ##
    ## Note that unlike ``times.DateTime``, ``SysTime`` is represented
    ## internally as a ``Time`` so this proc is just a field access.
    stime.time

proc toDateTime*(stime: SysTime): DateTime =
    ## Convert a ``SysTime`` to a ``times.DateTime``.
    stime.time.inZone(stime.timezone)

proc toSysTime*(dt: DateTime): SysTime =
    ## Convert a ``times.DateTime`` to a ``SysTime``.
    SysTime(time: toTime(dt), timezone: dt.timezone)

proc sysnow*(): SysTime =
    ## Get the current time as a ``SysTime``.
    SysTime(time: getTime(), timezone: local())

proc local*(stime: SysTime): SysTime =
    ## Shorthand for ``stime.inZone(local())``
    SysTime(time: stime.time, timezone: local())

proc utc*(stime: SysTime): SysTime =
    ## Shorthand for ``stime.inZone(utc())``
    SysTime(time: stime.time, timezone: utc())

proc isDst*(stime: SysTime): bool =
    ## Returns true if ``stime`` observes DST, and false if not.
    stime.timezone.zonedTimeFromTime(stime.time).isDst

proc utcOffset*(stime: Systime): int =
    ## Returns the timezone offset in seconds west of UTC.
    stime.timezone.zonedTimeFromTime(stime.time).utcOffset

template getDate(stime: SysTime):
        tuple[monthday: MonthdayRange, month: Month, year: int] =
    let unix = toUnix(stime.time) + stime.utcOffset
    let epochday = floorDiv(unix, convert(Days, Seconds, 1))
    fromEpochDay(epochday)

proc year*(stime: SysTime): int =
    getDate(stime).year

proc month*(stime: SysTime): Month =
    getDate(stime).month

proc monthday*(stime: SysTime): MonthdayRange =
    getDate(stime).monthday

proc hour*(stime: SysTime): HourRange =
    ## Returns the hour of the day in the range ``0 .. 23``.
    toDateTime(stime).hour

proc minute*(stime: SysTime): MinuteRange =
    ## Returns the minute of the hour in the range ``0 .. 59``
    floorMod(toUnix(stime.time) + stime.utcOffset, 60 * 60) div 60

proc second*(stime: SysTime): SecondRange =
    ## Returns the second of the minute in the range ``0 .. 59``.
    ##
    ## Note that the ``SecondRange`` type allows the range ``0 .. 60``
    ## because of leap seconds, but a leap second will never be returned
    ## by this proc.
    floorMod(toUnix(stime.time) + stime.utcOffset, 60)

proc nanosecond*(stime: SysTime): NanosecondRange =
    ## Returns the nanosecond of the second in the range ``0 .. 999_999_999``.
    # Since UTC offsets is only whole seconds,
    # we can return the nanosecond directly.
    stime.time.nanosecond

proc yearday*(stime: SysTime): YeardayRange =
    ## Returns the day of the year in the range ``0 .. 365``.
    let date = getDate(stime)
    getDayOfYear(date.monthday, date.month, date.year)

proc weekday*(stime: SysTime): Weekday =
    ## Returns the day of the week as an enum.
    getDayOfWeek(toUnix(stime.time) + stime.utcOffset)

proc `<`*(a, b: SysTime): bool =
    a.time < b.time

proc `<=`*(a, b: SysTime): bool =
    a.time <= b.time

proc `==`*(a, b: SysTime): bool =
    ## Returns true if ``a`` and ``b`` represent the same point in time.
    ## Note that the timezone doesn't need to match!
    runnableExamples:
        import times
        let a = sysnow()
        let b = a.inZone(utc())
        doAssert a == a
        doAssert a == b
    a.time == b.time

proc `-`*(a, b: SysTime): Duration =
    a.time - b.time

proc `+`*(stime: SysTime, dur: Duration): SysTime =
    SysTime(time: stime.time + dur, timezone: stime.timezone)

proc `-`*(stime: SysTime, dur: Duration): SysTime =
    SysTime(time: stime.time - dur, timezone: stime.timezone)

proc `+`*(stime: SysTime, interval: TimeInterval): SysTime =
    if isStaticInterval(interval):
        SysTime(time: stime.time + evaluateStaticInterval(interval),
            timezone: stime.timezone)
    else:
        # Expensive!
        toSysTime(toDateTime(stime) + interval)

proc `-`*(stime: SysTime, interval: TimeInterval): SysTime =
    if isStaticInterval(interval):
        SysTime(time: stime.time - evaluateStaticInterval(interval),
            timezone: stime.timezone)
    else:
        # Expensive!
        toSysTime(toDateTime(stime) - interval)

proc between*(low, high: SysTime): TimeInterval =
    between(toDateTime(low), toDateTime(high))

proc parseSysTime*(input, f: string, zone: Timezone): SysTime =
    SysTime(time: parseTime(input, f, zone), timezone: zone)

proc parseSysTime*(input, f: static[string], zone: Timezone): SysTime =
    SysTime(time: parseTime(input, f, zone), timezone: zone)

proc format*(stime: SysTime, f: TimeFormat): string =
    toDateTime(stime).format(f)

proc format*(stime: SysTime, f: string): string =
    toDateTime(stime).format(f)
    
proc format*(stime: SysTime, f: static[string]): string =
    toDateTime(stime).format(f)

proc `$`*(stime: SysTime): string =
    ## Stringification of a ``SysTime``.
    ## Uses the same format as ``times.$`` for ``times.DateTime``.
    $toDateTime(stime)