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
  @config Application.get_env(:toolex, Toolex.ErrorReporter)
  @exclude_envs @config[:exclude_envs] || [:test]
  @env Mix.env

  def report(reason, _metadata, _context) when @env in @exclude_envs do
    raise reason
  end

  def report(reason, metadata, context) do
    Logger.error "#{inspect reason}"
    Bugsnag.report reason, [
      metadata: metadata,
      context: context
    ]
  end
end
