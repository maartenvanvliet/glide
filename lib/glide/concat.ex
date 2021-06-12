defprotocol Glide.Concat do
  def concat(data1, data2)
end

defimpl Glide.Concat, for: String do
  def concat(data1, data2) do
    data1 <> data2
  end
end

defimpl Glide.Concat, for: BitString do
  def concat(data1, data2) do
    data1 <> data2
  end
end

defimpl Glide.Concat, for: List do
  def concat(data1, data2) do
    data1 ++ data2
  end
end
