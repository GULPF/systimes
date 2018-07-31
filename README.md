NOTE: This module is still in an early stage

systimes
===========================

The ``systimes`` module implements an alternative way to represent a ``timestamp`` + ``timezone``.
Nim's standard library uses the ``DateTime`` type to represent it. There are two important
differences between ``DateTime`` and ``SysTime``:

- ``SysTime`` is immutable.
- ``SysTime`` is implemented as an object consisting of a ``times.Time`` and a ``times.Timezone``,
  meaning that individual caledar fields like year, month and so on are never stored.

Some things to keep in mind:

- When the calendar fields are accessed several times for the same object, there is a performance penalty
 when using ``SysTime`` since they must be computed at every access.
- Many procs are faster for ``SysTime``. Notably all procs involving ``Duration`` since they not longer
 require timezone information.
- Some procs are slower for ``SysTime``. Notably all procs involving ``TimeInterval``. 
- ``SysTime`` is much more space effecient.

``systimes`` is implemented as a complement to the ``times`` module, not a replacement. It's compatible with
types like ``Duration`` and ``TimeInterval`` from the ``times`` module, and offers a very similiar API as
the ``DateTime`` type.

The name comes from the ``SysTime`` class from Phobos, which uses a similiar representation for ``timestamp`` + ``timezone``.

### Examples
```nim
import systimes, times
let x = sysnow()
let y = initSysTime(01, mJan, 2000, 12, 00, 00, utc())
doAssert x > y
echo y # 2000-01-01T12:00:00Z
```

Compatibility with the times module
-----------------------
``systimes`` exposes a very similiar API for ``SysTime`` as the ``times`` module does for ``DateTime``.
Notable differences are listed in the table below. Note that the ``systimes`` module doesn't cause any conflict or ambiguities with the ``times`` modules, so importing both from the same module is a good idea.

| DateTime                 | SysTime                         |
|--------------------------|---------------------------------|
| ``now()``                | ``sysnow()``                    |
| ``parse(input, format)`` | ``parseSysTime(input, format)`` |
| ``time.inZone(zone)``    | ``initSysTime(time, zone)``     |
| ``initDateTime(...)``    | ``initSysTime(...)``            |