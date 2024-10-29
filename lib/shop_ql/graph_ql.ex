defmodule ShopQL.GraphQL do
  def schema_to_fragments(schema) do
    traverse_embedded_schemas(schema, MapSet.new([schema]))
    |> MapSet.to_list()
    |> Enum.map(&schema_to_fragment/1)
    |> Enum.join("\n")
  end

  # Recursively traverse graph of embedded schemas, adding them to `set` accumulator. Returns
  # accumulated set.
  defp traverse_embedded_schemas(schema, set) do
    Enum.reduce(schema.__schema__(:embeds), set, fn embed_name, set ->
      related = schema.__schema__(:embed, embed_name).related

      if MapSet.member?(set, related) do
        set
      else
        traverse_embedded_schemas(related, MapSet.put(set, related))
      end
    end)
  end

  defp schema_to_fragment(schema) do
    name = type_name(schema)

    connection_fields =
      if function_exported?(schema, :connection_fields, 0) do
        schema.connection_fields()
      else
        []
      end

    embed_and_connection_fields = schema.__schema__(:embeds)
    embed_fields = embed_and_connection_fields -- connection_fields
    fields = schema.__schema__(:fields) -- embed_and_connection_fields

    # NOTE: current implementation doesn't provide a way to paginate connections
    connections_gql =
      Enum.map(connection_fields, fn field ->
        name = schema.__schema__(:embed, field).related |> type_name()

        "  #{camelized_name(field)}(first: 250) { pageInfo { hasNextPage }, nodes { ...#{fragment_name(name)} } }"
      end)

    embeds_gql =
      Enum.map(embed_fields, fn field ->
        name = schema.__schema__(:embed, field).related |> type_name()

        "  #{camelized_name(field)} { ...#{fragment_name(name)} }"
      end)

    """
    fragment #{fragment_name(name)} on #{name} {
      #{fields |> Enum.map(&camelized_name/1) |> Enum.join(",")}
    #{Enum.join(connections_gql, "\n")}
    #{Enum.join(embeds_gql, "\n")}
    }
    """
  end

  defp camelized_name(atom) do
    <<first::utf8, rest::binary>> = atom |> Atom.to_string() |> Macro.camelize()
    String.downcase(<<first::utf8>>) <> rest
  end

  defp type_name(schema) do
    schema |> Atom.to_string() |> String.split(".") |> List.last()
  end

  defp fragment_name(name) do
    "#{name}Fragment"
  end
end
