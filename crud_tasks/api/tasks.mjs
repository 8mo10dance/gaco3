import { apiRequest } from "./base.mjs"

// GET all tasks
export async function getList() {
  return apiRequest('/api/v1/tasks')
}

// GET a single task by ID
export async function getItem(id) {
  return apiRequest(`/api/v1/tasks/${id}`)
}

// POST a new task
export async function createItem(taskData) {
  return apiRequest('/api/v1/tasks', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(taskData),
  })
}

// PUT/PATCH to update an existing task
export async function updateItem(id, taskData) {
  return apiRequest(`/api/v1/tasks/${id}`, {
    method: 'PATCH', // Or 'PUT' depending on API preference for full replacement vs partial update
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(taskData),
  })
}

// DELETE a task
export async function deleteItem(id) {
  return apiRequest(`/api/v1/tasks/${id}`, {
    method: 'DELETE',
  })
}
