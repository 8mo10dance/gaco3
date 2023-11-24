import { Controller } from "@hotwired/stimulus"
import qs from 'qs'

export default class extends Controller {
  async changeImage(event) {
    const file = event.target.files[0]
    if (!file) return

    try {
      const { url, path } = await getPresignedUrl(file)
      const response = await uploadFile(url, file)
      if (!response.ok) throw Error('Failed to upload the file')
    } catch (err) {
      console.log(err)
    }
  }
}

async function getPresignedUrl(file) {
  const params = qs.stringify({ filename: file.name, 'content_type': file.type })
  const response = await fetch(`/api/v1/presigned_url?${params}`)
  if (!response.ok) throw Error('Invalid response')

  const data = await response.json()
  return data
}

function uploadFile(url, file) {
  const formData = new FormData()
  formData.append('file', file)
  const headers = {
    accept: 'multipart/form-data'
  }
  return fetch(url, { method: 'PUT', headers, body: formData })
}
