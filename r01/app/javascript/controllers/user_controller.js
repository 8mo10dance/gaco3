import { Controller } from "@hotwired/stimulus"

import { apiRequest } from '../helpers/api'

export default class extends Controller {
  static targets = ['avatarIdField', 'avatarImageArea']

  set avatarId(avatarId) {
    this.avatarIdFieldTarget.value = avatarId
  }

  set avatarImageUrl(avatarImageUrl) {
    const imageEl = document.createElement('img')
    imageEl.src = avatarImageUrl
    imageEl.alt = ''
    this.avatarImageAreaTarget.appendChild(imageEl)
  }

  async changeAvatar(event) {
    const file = event.target.files[0]
    if (!file) return

    try {
      const response = await uploadUserAvatar(file)
      if (response.ok) {
        const data = await response.json()
        this.avatarId = data['user_avatar_id']
        this.avatarImageUrl = data['user_avatar_url']
      }
    } catch (err) {
      console.log(err)
    }
  }
}

function uploadUserAvatar(file) {
  const formData = new FormData()
  formData.append("user_avatar[image]", file)

  return apiRequest('/api/v1/user_avatars', { method: 'POST', body: formData })
}
