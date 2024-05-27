class Project < TaskBase
  def filename
    return if title.blank?

    if area_title
      "#{area_title.parameterize}/#{title.parameterize}.org"
    else
      "#{title.parameterize}.org"
    end
  end

  private

  def area_title
    return nil if area_id.blank?

    Area::STORE.find { |area| area.id == area_id }&.title
  end
end

Project::STORE = []
