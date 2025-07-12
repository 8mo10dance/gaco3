import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

import { getList, getItem, createItem, updateItem, deleteItem } from "./api/tasks.mjs"

const server = new McpServer({
  name: "Task MCP",
  version: "1.0.0",
});

server.tool(
  "get_tasks",
  "タスク一覧を取得する",
  {},
  getTasks,
);

server.tool(
  "get_task",
  "特定の id のタスクを取得する",
  { id: z.number() },
  getTask,
);

server.tool(
  "create_task",
  "タスクを作成する",
  { title: z.string(), content: z.string() },
  createTask,
);

server.tool(
  "update_task",
  "特定の id のタスクを更新する",
  { id: z.number(), title: z.string(), content: z.string() },
  updateTask,
);

server.tool(
  "delete_task",
  "特定の id のタスクを削除する",
  { id: z.number() },
  deleteTask,
);

const transport = new StdioServerTransport();
await server.connect(transport);

async function getTasks() {
  try {
    console.log('Fetching all tasks...');
    const tasks = await getList()
    console.log('All tasks:', tasks);
    return { content: [{ type: "text", text: JSON.stringify(tasks) }] }
  } catch (error) {
    console.error('Error fetching tasks:', error);
  }
}

async function getTask({ id }) {
  try {
    console.log(`Fetching task with ID: ${id}...`);
    const task = await getItem(id)
    console.log(`Task with ID ${id}:`, task);
    return { content: [{ type: "text", text: JSON.stringify(task) }] }
  } catch (error) {
    console.error(`Error fetching task with ID ${id}:`, error);
  }
}

async function createTask({ id, ...taskData }) {
  try {
    console.log('Creating new task with data:', taskData);
    const newTask = await createItem({ task: taskData })
    console.log('New task created:', newTask);
    return { content: [{ type: "text", text: JSON.stringify(newTask) }] }
  } catch (error) {
    console.error('Error creating task:', error);
  }
}

async function updateTask({ id, ...taskData }) {
  try {
    console.log(`Updating task with ID: ${id} with data:`, taskData);
    const updatedTask = await updateItem(id, { task: taskData })
    console.log(`Task with ID ${id} updated:`, updatedTask);
    return { content: [{ type: "text", text: JSON.stringify(updatedTask) }] }
  } catch (error) {
    console.error(`Error updating task with ID ${id}:`, error);
  }
}

async function deleteTask({ id }) {
  try {
    console.log(`Deleting task with ID: ${id}...`);
    await deleteItem(id)
    console.log(`Task with ID ${id} deleted successfully.`);
    return { content: [{ type: "text", text: '削除しました' }] }
  } catch (error) {
    console.error(`Error deleting task with ID ${id}:`, error);
    return false;
  }
}
