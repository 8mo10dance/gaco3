import { jest } from '@jest/globals'

jest.unstable_mockModule('./base.mjs', () => ({
  apiRequest: jest.fn(),
}))

const { getList, getItem, createItem, updateItem, deleteItem } = await import('./tasks.mjs')
const { apiRequest } = await import('./base.mjs')

describe('tasks API helpers', () => {
  beforeEach(() => {
    apiRequest.mockReset()
  })

  test('getList fetches all tasks', async () => {
    apiRequest.mockResolvedValue('all')
    const result = await getList()
    expect(apiRequest).toHaveBeenCalledWith('/api/v1/tasks')
    expect(result).toBe('all')
  })

  test('getItem fetches a single task', async () => {
    apiRequest.mockResolvedValue('single')
    const result = await getItem(1)
    expect(apiRequest).toHaveBeenCalledWith('/api/v1/tasks/1')
    expect(result).toBe('single')
  })

  test('createItem posts new task', async () => {
    const data = { title: 't' }
    apiRequest.mockResolvedValue('created')
    const result = await createItem(data)
    expect(apiRequest).toHaveBeenCalledWith('/api/v1/tasks', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    })
    expect(result).toBe('created')
  })

  test('updateItem patches existing task', async () => {
    const data = { title: 'u' }
    apiRequest.mockResolvedValue('updated')
    const result = await updateItem(2, data)
    expect(apiRequest).toHaveBeenCalledWith('/api/v1/tasks/2', {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    })
    expect(result).toBe('updated')
  })

  test('deleteItem removes a task', async () => {
    apiRequest.mockResolvedValue(true)
    const result = await deleteItem(3)
    expect(apiRequest).toHaveBeenCalledWith('/api/v1/tasks/3', { method: 'DELETE' })
    expect(result).toBe(true)
  })
})
