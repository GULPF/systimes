import times, math

type
    SysTime* = object ## Represents a point-in-time with
                      ## an attached timezone.
        time: Time
        timezone: Timezone

proc timezone*(stime: SysTime): Timezone =
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
    let zoneInfo = zone.zoneInfoFromTz(dt.toAdjTime)
    let time = zoneInfo.adjTime + initDuration(seconds = zoneInfo.utcOffset)
    result = SysTime(time: time, timezone: zone)

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
    ## Note that unlike ``DateTime``, ``SysTime`` is represented
    ## internally as a ``Time`` so this proc is just a field access.
    stime.time

proc toDateTime*(stime: SysTime): DateTime =
    ## Convert ``SysTime`` to ``DateTime``.
    stime.time.inZone(stime.timezone)

proc toSysTime*(dt: DateTime): SysTime =
    ## Convert ``DateTime`` to ``SysTime``.
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
    stime.timezone.zoneInfoFromUtc(stime.time).isDst

proc utcOffset*(stime: Systime): int =
    ## Returns the timezone offset in seconds west of UTC.
    stime.timezone.zoneInfoFromUtc(stime.time).utcOffset

# TODO: Optimize
proc year*(stime: SysTime): int               = toDateTime(stime).year
proc month*(stime: SysTime): Month            = toDateTime(stime).month
proc monthday*(stime: SysTime): MonthdayRange = toDateTime(stime).monthday

proc hour*(stime: SysTime): HourRange =
    toDateTime(stime).hour

proc minute*(stime: SysTime): MinuteRange =
    floorMod(toUnix(stime.time) + stime.utcOffset, 60 * 60) div 60

proc second*(stime: SysTime): SecondRange =
    floorMod(toUnix(stime.time) + stime.utcOffset, 60)

proc nanosecond*(stime: SysTime): NanosecondRange =
    # Since UTC offsets is only whole seconds,
    # we can return the nanosecond directly.
    stime.time.nanosecond

proc yearday*(stime: SysTime): YeardayRange =
    # TODO: optimize
    toDateTime(stime).yearday

proc weekday*(stime: SysTime): Weekday =
    getDayOfWeek(toUnix(stime.time) + stime.utcOffset)

proc `<`*(a, b: SysTime): bool =
    a.time < b.time

proc `<=`*(a, b: SysTime): bool =
    a.time <= b.time

proc `==`*(a, b: SysTime): bool =
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
    ## Uses the same format as ``DateTime``.
    $toDateTime(stime)