defmodule Mix.Tasks.Loc do
  @moduledoc "Pass a directory to count the lines of code in it"
  use Mix.Task

  @shortdoc "Pass a directory to count the lines of code in it"
  def run([path]) do
    Mix.Task.run("compile")
    LocCounter.count_lines(path)
  end

  @shortdoc "calls the loc_counter module for the current directory"
  def run(_) do
    Mix.Task.run("compile")
    LocCounter.count_lines(".")
  end
end
