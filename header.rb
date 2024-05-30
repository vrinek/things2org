require_relative "org_tasks"

class Header < TaskBase
  def project_id
    last_event_prop("pr")&.first
  end

  def to_org
    org_header + OrgTasks.new(tasks).to_org
  end

  private

  def org_header
    "* #{title}\n"
  end

  def tasks
    Task::STORE.select { |task| task.header_id == id }
  end
end

Header::STORE = []
