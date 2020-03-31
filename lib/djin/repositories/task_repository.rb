class TaskRepository
  def initialize(tasks = [])
    @tasks = tasks
  end

  def add(*tasks)
    @tasks += tasks
  end

  def all
    @tasks
  end

  def find_by_names(names)
    @tasks.select { |task| names.include?(task.name) }
  end
end
