systimes
===========================

The ``systimes`` module implements an alternative way to represent a ``timestamp`` + ``timezone``. Nim's standard library uses the ``DateTime`` type to represent the same thing. There are two important differences between ``DateTime`` and ``SysTime``:

- ``SysTime`` is immutable.
- ``SysTime`` only stores a ``times.Time`` and a ``times.Timezone``,
  meaning that individual calendar fields like year, month and so on are never stored.

Some things to keep in mind:

- When the calendar fields are accessed several times for the same object, there is a performance penalty when using ``SysTime`` since they must be computed at every access.
- Many procs are faster for ``SysTime``. Notably all procs involving ``Duration`` since they no longer require timezone information.
- Some procs are slower for ``SysTime``. Notably all procs involving ``TimeInterval``. 
- ``SysTime`` is much more space effecient.

The name ``SysTime`` comes from the [``SysTime`` class from Phobos](https://dlang.org/phobos/std_datetime_systime.html), which uses a similiar representation for ``timestamp`` + ``timezone``.

Usage
-----------------------
```nim
import systimes, times
let x = sysnow()
let y = initSysTime(01, mJan, 2000, 12, 00, 00, utc())
doAssert x > y
doAssert x < y + 10.years
echo y # 2000-01-01T12:00:00Z
```
- - -

``systimes`` exposes a very similiar API for ``SysTime`` as the ``times`` module does for ``DateTime``. Notable differences are listed in the table below. [Generated docs are available here](https://gulpf.github.io/systimes/systimes.html).

| DateTime                 | SysTime                         |
|--------------------------|---------------------------------|
| ``now()``                | ``sysnow()``                    |
| ``parse(input, format)`` | ``parseSysTime(input, format)`` |
| ``time.inZone(zone)``    | ``initSysTime(time, zone)``     |
| ``initDateTime(...)``    | ``initSysTime(...)``            |
