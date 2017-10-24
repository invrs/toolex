defmodule Toolex.ErrorReporter do
  @moduledoc """
  An error reporter.

  Requires the `:bugsnag` dependency to be added to your mix.exs file.

  To exclude certain envs from reporting (and re-raise it instead) use:

  ```
      config :toolex, Toolex.ErrorReporter, exclude_envs: [:test, :dev]
  ```

  Also dont' forget to add a Bugsnag API key:

  ```
      config :bugsnag, api_key: "<key>"
  ```
  """
  require Logger

  def report(reason, metadata, context) do
    config       = Application.get_env(:toolex, Toolex.ErrorReporter)
    exclude_envs = config[:exclude_envs] || [:test]

    if Mix.env() in exclude_envs do
      raise reason
    else
      Logger.error "#{inspect reason}"

      # TODO: Restore this!
      # Bugsnag.report reason, [
      #   metadata: metadata,
      #   context: context
      # ]
    end
  end
end
