import { getList, getItem, createItem, updateItem, deleteItem } from "./api/tasks.mjs"

async function getTasks() {
  try {
    console.log('Fetching all tasks...');
    const tasks = await getList()
    console.log('All tasks:', tasks);
    return tasks;
  } catch (error) {
    console.error('Error fetching tasks:', error);
  }
}

async function getTask(id) {
  try {
    console.log(`Fetching task with ID: ${id}...`);
    const task = await getItem(id)
    console.log(`Task with ID ${id}:`, task);
    return task;
  } catch (error) {
    console.error(`Error fetching task with ID ${id}:`, error);
  }
}

async function createTask(taskData) {
  try {
    console.log('Creating new task with data:', taskData);
    const newTask = await createItem(taskData)
    console.log('New task created:', newTask);
    return newTask;
  } catch (error) {
    console.error('Error creating task:', error);
  }
}

async function updateTask(id, taskData) {
  try {
    console.log(`Updating task with ID: ${id} with data:`, taskData);
    const updatedTask = await updateItem(id, taskData)
    console.log(`Task with ID ${id} updated:`, updatedTask);
    return updatedTask;
  } catch (error) {
    console.error(`Error updating task with ID ${id}:`, error);
  }
}

async function deleteTask(id) {
  try {
    console.log(`Deleting task with ID: ${id}...`);
    await deleteItem(id)
    console.log(`Task with ID ${id} deleted successfully.`);
    return true
  } catch (error) {
    console.error(`Error deleting task with ID ${id}:`, error);
    return false;
  }
}

// Example Usage (uncomment to test)
(async () => {
  // Get all tasks
  await getTasks();

  // Create a new task
  const newTask = await createTask({ title: 'Learn Gemini CLI', description: 'Master the new CLI agent' });

  // Get a single task (if newTask was created successfully)
  if (newTask && newTask.id) {
    await getTask(newTask.id);

    // Update the task
    await updateTask(newTask.id, { title: 'Learn Gemini CLI (Completed)', completed: true });

    // Delete the task
    await deleteTask(newTask.id);
  }
})();
