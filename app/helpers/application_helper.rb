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

  # Level system: an approved deviation from SPEC.md's "no levels in v1" —
  # see PLAN.md redesign notes. 100 points per level, flat.
  def level_for_points(points)
    (points / 100) + 1
  end

  def level_progress_percent(points)
    points % 100
  end

  def points_to_next_level(points)
    100 - level_progress_percent(points)
  end

  # Named tiers grouping levels — gaps roughly double each tier (2, 3, 5, 10,
  # 20, 40), extending the same shape the original 6-tier system already
  # had. level_for_points is unbounded (100 pts/level, no cap), so widening
  # the gap each tier keeps the top tier meaningfully far off rather than
  # reached by nearly everyone within a few weeks.
  LEVEL_TIERS = [
    [ 1, "Braise" ], [ 3, "Étincelle" ], [ 6, "Flammèche" ],
    [ 11, "Ardeur" ], [ 21, "Foyer" ], [ 41, "Brasier" ], [ 81, "Phare" ]
  ].freeze

  def level_tier_name(level)
    LEVEL_TIERS.reverse.find { |min, _| level >= min }.last
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
