export default class Observerable {
  constructor(initialValue) {
    this._value = initialValue
    this._subscribers = new Set()
  }

  get() {
    return this._value
  }

  set(newValue) {
    if (this._value === newValue) return

    this._value = newValue
    this._notify()
  }

  subscribe(f) {
    this._subscribers.add(f)
  }

  unsubscribe(f) {
    this._subscribers.delete(f)
  }

  _notify() {
    for (const f of this._subscribers) {
      f(this._value)
    }
  }
}
