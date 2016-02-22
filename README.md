# Toolex

A collection of Elixir helper classes/tools we use across apps.

Specifically:

### Toolex.ErrorReporter

An error reporter that reports to bugsnag.

### Toolex.ErrorReporter.Plug

A plug we can use in Routers to automatically report errors to Bugsnag using
`Toolex.ErrorReporter`.

## Installation

1. Add toolex to your list of dependencies in `mix.exs`:

      def deps do
        [{:toolex, github: "invrs/toolex"}]
      end
