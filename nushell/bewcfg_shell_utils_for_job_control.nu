# Shell utils for job control
# 👉 `jobs *` & `fg *` commands

# List running-but-frozen jobs / programs, to be resumed with `fg`
export def "jobs" [] {
  job list | where type == frozen | reject type
}

# Returns whether there are any running-but-frozen jobs / programs.
# Does NOT take other types of jobs into account (threads/..), use `job list` to see those.
export def "jobs any?" []: nothing -> bool {
  not (jobs | is-empty)
}

# Attempt to resume a frozen (suspended, with Ctrl-z) job in the shell.
# Use `last`, `before-last` or a job ID to select which job to resume.
# Simply prints an informational message if no last/before-last job.
export def "fg" [job_id?: int] {
  job unfreeze $job_id
}

# Attempt to resume the last frozen (suspended, with Ctrl-z) job in the shell.
# Simply prints an informational message if no jobs.
export def "fg last" [] {
  if not (jobs any?) {
    print "No running jobs"
    return
  }
  # By default, resumes the _last_ frozen job
  job unfreeze
}

# Attempt to resume the before-last (second-to-last) frozen (suspended, with Ctrl-z) job in the
# shell. Simply prints an informational message if not enough jobs.
#
# FIXME: Actually wrong impl.. There is no 'recent jobs' tracking
#   -> Need to impl `job list-recent` to list jobs in recently used order,
#   so `last` & `before-last` are _actually_ accurate.
export def "fg before-last" [] {
  let job_id = try { jobs | get 1.id } catch {
    print "Not enough running jobs"
    return
  }
  job unfreeze $job_id
}
