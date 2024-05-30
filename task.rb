require_relative "task_base"
require_relative "project"
require_relative "note"
require_relative "header"

class Task < TaskBase
  def to_org(level: 1)
    org_header(level:) + org_timings + org_properties + note.to_org
  end

  def project
    return Project::STORE.find { |project| project.id == project_id } if project_id

    header&.project
  end

  def header
    return if header_id.nil?

    Header::STORE.find { |header| header.id == header_id }
  end

  def belongs_to_project?
    project_id.present? || header_id.present?
  end

  def project_id
    last_event_prop("pr")&.first || header&.project_id
  end

  def header_id
    last_event_prop("agr")&.first
  end
end

Task::STORE = []
