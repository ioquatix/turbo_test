# TurboTest

[![Development Status](https://github.com/ioquatix/turbo_test/workflows/Test/badge.svg)](https://github.com/ioquatix/turbo_test/actions?workflow=Test)

## Proposal

Discourse contains two tools (highly recommend you try them out for context)

  - `bin/turbo_rspec` a parallel runner with non interleaving forking model. (leverages some of `parallel_test` … `rake parallel:create` / `migrate` to prep the dbs.
  - `bin/rake autospec` an automatic spec runner, which focuses on failed specs, like guard except that unlike guard it is interruptible.

Enter `turbo_test` (name TBD, suggestions welcome).

`turbo_test` will be a slot in replacement for the 2 tools Discourse use in a dedicated gem.

`turbo_test` is to first be fully functional with rspec runners but longer term should also work with `minitest`.

Features of the `turbo_test` gem:

  - MIT license, standard Rails code of conduct
  - Pull based model for forked test runners. Master process manages a queue of tests, forked processes pull from the queue. Transport long term is agnostic though I would recommend initial implementation uses pipes.
  - Pull model ensures that all the workers are running tests at all times. The parallel\_test model of splitting up the tests upfront means that workers are often idle for long periods of time.
  - Rake tasks for administration of partitioned test environments turbo\_test:create / migrate / drop
  - Non interleaved results (like `bin/turbo_rspec`)
  - While `turbo_rspec` is running, if you hit a specific key you can see right away information about the current tests that failed without halting the test process.
  - Documentation about how to handle custom sharding (memcached / redis) and so on.
  - Minimal changes required to Rails projects that decide to use this.
  - A key goal is deprecation of `bin/turbo_rspec` in Discourse.
  - Minimal dependencies (no explicit `rspec`, `minitest`, `redis`, `pg` dependencies)
  - Stretch goal, once this is all done … extract `bin/rake autospec` into this gem as well. (I will do a mini specification if we get there)
  - Extra long term stretch goal, pull these concepts back into Rails proper.

### Why not guard?

Guard at the moment does not support interruptible tests, this is a must have feature for `turbo_test`.

### Why not parallel\_test?

It does not support a pull model so it would be close to a ground up re-write.
