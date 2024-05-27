class ItemJsonMerger
  attr_reader :items_json

  def initialize
    @items_json = {
      "items" => []
    }
  end

  def add(json_file_path)
    @items_json["items"] += JSON[File.read(json_file_path)]["items"]
    @items_json["items"].uniq!

    self
  end

  def to_json
    @items_json.to_json
  end
end
