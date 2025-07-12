const BASE_URL = 'http://localhost:3000/api/v1/tasks';

async function handleResponse(response) {
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(`HTTP error! status: ${response.status}, message: ${errorData.message || JSON.stringify(errorData)}`);
  }
  return response.json();
}

// GET all tasks
async function getTasks() {
  try {
    const response = await fetch(BASE_URL);
    console.log('Fetching all tasks...');
    const tasks = await handleResponse(response);
    console.log('All tasks:', tasks);
    return tasks;
  } catch (error) {
    console.error('Error fetching tasks:', error);
  }
}

// GET a single task by ID
async function getTask(id) {
  try {
    const response = await fetch(`${BASE_URL}/${id}`);
    console.log(`Fetching task with ID: ${id}...`);
    const task = await handleResponse(response);
    console.log(`Task with ID ${id}:`, task);
    return task;
  } catch (error) {
    console.error(`Error fetching task with ID ${id}:`, error);
  }
}

// POST a new task
async function createTask(taskData) {
  try {
    const response = await fetch(BASE_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(taskData),
    });
    console.log('Creating new task with data:', taskData);
    const newTask = await handleResponse(response);
    console.log('New task created:', newTask);
    return newTask;
  } catch (error) {
    console.error('Error creating task:', error);
  }
}

// PUT/PATCH to update an existing task
async function updateTask(id, taskData) {
  try {
    const response = await fetch(`${BASE_URL}/${id}`, {
      method: 'PATCH', // Or 'PUT' depending on API preference for full replacement vs partial update
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(taskData),
    });
    console.log(`Updating task with ID: ${id} with data:`, taskData);
    const updatedTask = await handleResponse(response);
    console.log(`Task with ID ${id} updated:`, updatedTask);
    return updatedTask;
  } catch (error) {
    console.error(`Error updating task with ID ${id}:`, error);
  }
}

// DELETE a task
async function deleteTask(id) {
  try {
    const response = await fetch(`${BASE_URL}/${id}`, {
      method: 'DELETE',
    });
    console.log(`Deleting task with ID: ${id}...`);
    if (response.status === 204) { // No Content for successful deletion
      console.log(`Task with ID ${id} deleted successfully.`);
      return true;
    }
    await handleResponse(response); // Still try to parse if there's content for error
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
