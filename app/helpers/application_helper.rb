module ApplicationHelper
  def nav_tab_active?(*controllers)
    controllers.include?(controller_name)
  end

  # The "Courses" tab jumps straight to the most-recently-used list (its own
  # chip switcher covers the rest) rather than an index-of-lists page, so
  # there's somewhere useful to land with one tap.
  def courses_entry_path
    list = ShoppingList.ordered.first
    list ? shopping_list_path(list) : shopping_lists_path
  end

  def relative_day_label(date)
    days = (date - Date.current).to_i
    case days
    when 0 then "aujourd'hui"
    when 1 then "demain"
    when (2..) then "dans #{days} jours"
    else l(date, format: :short)
    end
  end
end
