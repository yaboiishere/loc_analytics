defmodule LocCounter do
  @language_comments %{
    "ex" => ["#"],
    "exs" => ["#"],
    "py" => ["#"],
    "rb" => ["#"],
    "sh" => ["#"],
    "yml" => ["#"],
    "html" => ["<!--", "-->"],
    "md" => ["<!--", "-->"],
    "css" => ["/*", "*/"],
    "c" => ["//", "/*", "*/"],
    "h" => ["//", "/*", "*/"],
    "cpp" => ["//", "/*", "*/"],
    "hpp" => ["//", "/*", "*/"],
    "java" => ["//", "/*", "*/"],
    "js" => ["//", "/*", "*/"]
  }

  defstruct [:loc, :comments, :empty_lines]

  defmodule FileData do
    defstruct [:extension, :contents]
  end

  def read_file(file) do
    read_file(%{}, file)
  end

  defp read_file(acc, path) do
    path
    |> Path.basename()
    |> String.match?(~r/^[\._]\w+/)
    |> case do
      true ->
        nil

      false ->
        path
        |> File.dir?()
        |> case do
          true ->
            path
            |> File.ls!()
            |> Enum.map(&Path.join(path, &1))
            |> Enum.reduce(%{}, fn file, inner_acc ->
              inner_acc
              |> read_file(file)
              |> case do
                nil ->
                  inner_acc

                ret ->
                  ret
              end
            end)
            |> then(fn files ->
              Map.put(acc, path, files)
            end)

          false ->
            path
            |> File.read!()
            |> String.split("\n")
            |> then(fn lines ->
              ext =
                path
                |> Path.basename()
                |> String.split(".")
                |> List.last()

              Map.put(acc, path, %FileData{extension: ext, contents: lines})
            end)
        end
    end
  end

  def count_lines(path) when is_binary(path) do
    path
    |> read_file()
    |> count_lines()
    |> IO.inspect()
  end

  def count_lines(%{} = files) do
    files
    |> Enum.reduce(%LocCounter{loc: 0, comments: 0, empty_lines: 0}, fn
      {_, %FileData{contents: lines, extension: ext}}, acc ->
        %LocCounter{loc: loc, comments: comments, empty_lines: empty_lines} =
          count_lines(ext, lines)

        %LocCounter{
          loc: acc.loc + loc,
          comments: acc.comments + comments,
          empty_lines: acc.empty_lines + empty_lines
        }

      {_, %{} = inner_files}, acc ->
        %LocCounter{loc: loc, comments: comments, empty_lines: empty_lines} =
          count_lines(inner_files)

        %LocCounter{
          loc: acc.loc + loc,
          comments: acc.comments + comments,
          empty_lines: acc.empty_lines + empty_lines
        }
    end)
  end

  defp count_lines(language, lines) when is_list(lines) and is_binary(language) do
    @language_comments
    |> Map.fetch(language)
    |> case do
      {:ok, comments} ->
        count_lines(comments, lines)

      :error ->
        %LocCounter{loc: Enum.count(lines), comments: 0, empty_lines: 0}
    end
  end

  defp count_lines(_language, []) do
    %LocCounter{loc: 0, comments: 0, empty_lines: 0}
  end

  defp count_lines([comment_symbol], lines) do
    Enum.reduce(lines, %LocCounter{loc: 0, comments: 0, empty_lines: 0}, fn line, acc ->
      line
      |> String.trim()
      |> String.starts_with?(comment_symbol)
      |> case do
        true ->
          %LocCounter{
            loc: acc.loc,
            comments: acc.comments + 1,
            empty_lines: acc.empty_lines
          }

        false ->
          line
          |> case do
            "" ->
              %LocCounter{
                loc: acc.loc,
                comments: acc.comments,
                empty_lines: acc.empty_lines + 1
              }

            _ ->
              %LocCounter{
                loc: acc.loc + 1,
                comments: acc.comments,
                empty_lines: acc.empty_lines
              }
          end
      end
    end)
  end

  defp count_lines([start_comment_symbol, end_comment_symbol], lines) do
    Enum.reduce(lines, %LocCounter{loc: 0, comments: 0, empty_lines: 0}, fn line, acc ->
      line
      |> String.trim()
      |> String.starts_with?(start_comment_symbol)
      |> case do
        true ->
          %LocCounter{
            loc: acc.loc,
            comments: acc.comments + 1,
            empty_lines: acc.empty_lines
          }

        false ->
          line
          |> String.ends_with?(end_comment_symbol)
          |> case do
            true ->
              %LocCounter{
                loc: acc.loc,
                comments: acc.comments + 1,
                empty_lines: acc.empty_lines
              }

            false ->
              line
              |> case do
                "" ->
                  %LocCounter{
                    loc: acc.loc,
                    comments: acc.comments,
                    empty_lines: acc.empty_lines + 1
                  }

                _ ->
                  %LocCounter{
                    loc: acc.loc + 1,
                    comments: acc.comments,
                    empty_lines: acc.empty_lines
                  }
              end
          end
      end
    end)
  end

  defp count_lines([comment_symbol, start_comment_symbol, end_comment_symbol], lines) do
    Enum.reduce(lines, %LocCounter{loc: 0, comments: 0, empty_lines: 0}, fn line, acc ->
      line
      |> String.trim()
      |> String.starts_with?(comment_symbol)
      |> case do
        true ->
          %LocCounter{
            loc: acc.loc,
            comments: acc.comments + 1,
            empty_lines: acc.empty_lines
          }

        false ->
          case String.starts_with?(line, start_comment_symbol) do
            true ->
              %LocCounter{
                loc: acc.loc,
                comments: acc.comments + 1,
                empty_lines: acc.empty_lines
              }

            false ->
              case String.ends_with?(line, end_comment_symbol) do
                true ->
                  %LocCounter{
                    loc: acc.loc,
                    comments: acc.comments + 1,
                    empty_lines: acc.empty_lines
                  }

                false ->
                  case String.starts_with?(line, end_comment_symbol) do
                    true ->
                      %LocCounter{
                        loc: acc.loc,
                        comments: acc.comments + 1,
                        empty_lines: acc.empty_lines
                      }

                    false ->
                      case String.trim(line) do
                        "" ->
                          %LocCounter{
                            loc: acc.loc,
                            comments: acc.comments,
                            empty_lines: acc.empty_lines + 1
                          }

                        _ ->
                          %LocCounter{
                            loc: acc.loc + 1,
                            comments: acc.comments,
                            empty_lines: acc.empty_lines
                          }
                      end
                  end
              end
          end
      end
    end)
  end
end
