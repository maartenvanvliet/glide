defprotocol Glide.Merge do
  def merge(data1, data2)
end

defimpl Glide.Merge, for: Map do
  def merge(data1, data2) when is_list(data2) do
    Map.merge(data1, Map.new(data2))
  end

  def merge(data1, data2) do
    Map.merge(data1, data2)
  end
end
