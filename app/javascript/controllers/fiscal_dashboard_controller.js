import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "row", "filterForm", "emissionSelect", "competenceFilter", "competenceButton"]

  connect() {
    if (!this.hasEmissionSelectTarget) return

    this.onEmissionChange = () => {
      this.filterFormTarget.querySelectorAll('input[name="competence_months[]"]').forEach((input) => {
        input.checked = false
      })
      this.filterFormTarget.requestSubmit()
    }
    this.emissionSelectTarget.addEventListener("change", this.onEmissionChange)
  }

  disconnect() {
    if (this.hasEmissionSelectTarget && this.onEmissionChange) {
      this.emissionSelectTarget.removeEventListener("change", this.onEmissionChange)
    }
  }

  toggleCompetences(event) {
    event.stopPropagation()
    const open = !this.competenceFilterTarget.classList.contains("fa-filter--open")
    this.competenceFilterTarget.classList.toggle("fa-filter--open", open)
    this.competenceButtonTarget.setAttribute("aria-expanded", open.toString())
  }

  closeCompetences(event) {
    if (!this.hasCompetenceFilterTarget || this.competenceFilterTarget.contains(event.target)) return

    this.competenceFilterTarget.classList.remove("fa-filter--open")
    this.competenceButtonTarget.setAttribute("aria-expanded", "false")
  }

  togglePeriodSelector(event) {
    event.stopPropagation()
    const selector = event.currentTarget.closest("[data-period-selector]")
    const open = !selector.classList.contains("fa-period-select--open")

    this.closeAllPeriodSelectors(selector)
    selector.classList.toggle("fa-period-select--open", open)
    event.currentTarget.setAttribute("aria-expanded", open.toString())
  }

  closePeriodSelectors(event) {
    const activeSelector = event.target.closest?.("[data-period-selector]")
    this.closeAllPeriodSelectors(activeSelector)
  }

  clearPeriodSelector(event) {
    const selector = event.currentTarget.closest("[data-period-selector]")
    selector.querySelectorAll('input[type="checkbox"]').forEach((input) => { input.checked = false })
    this.updatePeriodSummary(selector)
  }

  periodChanged(event) {
    const input = event.currentTarget
    const selector = input.closest("[data-period-selector]")

    if (input.checked && input.dataset.periodYear) {
      selector.querySelectorAll(`[data-period-month^="${input.dataset.periodYear}-"]`).forEach((month) => { month.checked = false })
    } else if (input.checked && input.dataset.periodMonth) {
      const year = input.dataset.periodMonth.slice(0, 4)
      const yearInput = selector.querySelector(`[data-period-year="${year}"]`)
      if (yearInput) yearInput.checked = false
    }

    this.updatePeriodSummary(selector)
  }

  closeAllPeriodSelectors(except = null) {
    this.element.querySelectorAll("[data-period-selector]").forEach((selector) => {
      if (selector === except) return

      selector.classList.remove("fa-period-select--open")
      selector.querySelector(".fa-period-select__trigger")?.setAttribute("aria-expanded", "false")
    })
  }

  updatePeriodSummary(selector) {
    const labels = [...selector.querySelectorAll('input[type="checkbox"]:checked')].map((input) => input.dataset.periodLabel)
    selector.querySelector("[data-period-summary]").textContent = labels.length > 0 ? labels.join(", ") : "Todos os anos e meses"
  }

  search() {
    const query = this.searchTarget.value.trim().toLocaleLowerCase("pt-BR")
    this.rowTargets.forEach((row) => {
      row.hidden = query.length > 0 && !row.dataset.search.includes(query)
    })
  }
}