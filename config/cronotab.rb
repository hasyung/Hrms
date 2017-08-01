# cronotab.rb — Crono configuration file
#
# Here you can specify periodic jobs and schedule.
# You can use ActiveJob's jobs from `app/jobs/`
# You can use any class. The only requirement is that
# class should have a method `perform` without arguments.
#

Crono.perform(FutureTask).every 10.minutes
Crono.perform(ContinuaTask).every 1.days, at: {hour: 01, min: 00}
