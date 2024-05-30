require_relative "task_base"
require_relative "org_file_title"

class Project < TaskBase
  def filename
    return if title.blank?

    if area_title
      "#{area_title.parameterize}/#{title.parameterize}.org"
    else
      "#{title.parameterize}.org"
    end
  end

  def to_org
    things_id_property = <<~ORG
      #+PROPERTY: things_id #{id}
    ORG

    OrgFileTitle.new(title).to_org +
      things_id_property +
      note.to_org +
      tasks_org(tasks)
  end

  private

  def area_title
    return nil if area_id.blank?

    Area::STORE.find { |area| area.id == area_id }&.title
  end

  def tasks
    Task::STORE.select { |task| task.project_id == id }
  end

  def tasks_org(tasks)
    org = tasks.sort_by(&:index).map(&:to_org).join("\n")
    org = "\n" + org unless org.blank?
    org
  end
end

Project::STORE = []
