class OrgTasks
  def initialize(tasks)
    @tasks = tasks
  end

  def to_org
    org = @tasks.sort_by(&:index).map { |t| t.to_org(level: 2)}.join("\n")
    org = "\n" + org unless org.blank?
    org
  end
end
