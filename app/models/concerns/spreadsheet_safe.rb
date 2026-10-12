# Text prefixed with an apostrophe when a spreadsheet would otherwise run it as a formula.
module SpreadsheetSafe
  FORMULA_START = /\A[=+\-@\t\r]/

  private

  def safe(value)
    value.is_a?(String) && value.match?(FORMULA_START) ? "'#{value}" : value
  end
end
