require_relative "task_base"
require_relative "project"
require_relative "note"
require_relative "header"
require_relative "checklist_item"

class Task < TaskBase
  def to_org(level: 1)
    org = org_header(level:)
    org << org_timings
    org << org_properties
    org << note.to_org(level: level + 1)

    if checklist_items.any?
      org << "\n"
      org << checklist_items.map(&:to_org).join
    end

    org
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

  def checklist_items
    ChecklistItem::STORE.select { |item| item.task_id == id }
      .sort_by(&:index)
  end
end

Task::STORE = []
