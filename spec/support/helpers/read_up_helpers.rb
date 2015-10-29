module ReadUpHelpers
  def read_up
    File.read(read_up_path)
  end

  def read_up_path
    relative_path = "../../../config/contents/duplicated_code.md"
    File.expand_path(
      File.join(File.dirname(__FILE__), relative_path)
    )
  end
end
