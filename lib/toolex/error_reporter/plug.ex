defmodule Toolex.ErrorReporter.Plug do
  defmacro __using__(_env) do
    quote do
      use Plug.ErrorHandler

      defp handle_errors(_, %{reason: %Phoenix.Router.NoRouteError{}}), do: nil
      defp handle_errors(conn, %{reason: reason}) do
        Toolex.ErrorReporter.report(
          reason,
          %{
            params:  Map.delete(conn.params, "_token"),
            headers: Enum.into(conn.req_headers, %{}),
          },
          "#{conn.method} /#{Enum.join(conn.path_info, "/")}"
        )
      end
    end
  end
end
