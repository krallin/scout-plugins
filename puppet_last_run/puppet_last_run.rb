class PuppetLastRun < Scout::Plugin
  needs 'yaml'

OPTIONS=<<-EOS
  data_file:
    default: /var/lib/puppet/state/last_run_summary.yaml
    notes: "Either the path to a last_run_summary.yaml file or the recent_runs.yaml file (prior versions)."
EOS

  DEFAULT_RECENT_RUNS_FILE="/var/lib/puppet/state/recent_runs.yaml"

  def build_report
    recent_runs_file = option(:data_file) || DEFAULT_RECENT_RUNS_FILE

    if File.exist?(recent_runs_file)
      actual_last_run_time = File.mtime(recent_runs_file)
      scout_last_run_time  = memory(:last_run_time)

      return if scout_last_run_time && scout_last_run_time >= actual_last_run_time

      remember :last_run_time => actual_last_run_time

      read_file(recent_runs_file)
    else
      error("Puppet run file does not exist")
    end
  end
  
  # It looks like different versions of Puppet generate different data files. 
  # Version 2.6.2 generates a recent_runs.yaml file w/exit codes. 
  # Version 3.1 generates more detailed files - last_run_summary.yaml and last_run_report.yaml. We'll look at the summary.
  def read_file(file)
    # recent_array   = YAML.load_file(recent_runs_file) || []
    data  = YAML.load_file(file)
    if data.is_a?(Array)
      last_exit_code = data.last || 4
      report(:success => (last_exit_code <= 2) ? 1 : 0)
    else
      report(
        :events_total => data['events']['total'],
        :events_failure => data['events']['failure'],
        :resources_total => data['resources']['total'],
        :resources_failure => data['resources']['failed'],
        :changes_total => data['changes']['total']
      )
    end
  end
end