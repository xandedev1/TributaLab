import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "focusedRow"]

  connect() {
    if (!this.hasFocusedRowTarget) return

    requestAnimationFrame(() => {
      const top = this.focusedRowTarget.offsetTop - (this.gridTarget.clientHeight / 2)
      this.gridTarget.scrollTo({ top: Math.max(top, 0), behavior: "smooth" })
    })
  }
}