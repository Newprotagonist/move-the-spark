# The per-occurrence completion log. A single recurring `Goal` row is
# completed many times (once per due day/week); `occurred_on` identifies
# which occurrence this row is for — the exact date for a daily goal, the
# week's Monday for a weekly goal.
class GoalCompletion < ApplicationRecord
  belongs_to :goal

  validates :occurred_on, presence: true, uniqueness: { scope: :goal_id }
  validates :completed_at, presence: true
  validates :points_awarded, numericality: { greater_than_or_equal_to: 0 }

  # Bulk-loads completions for a set of (goal_id, occurred_on) pairs and
  # indexes them by that same pair, so a view can look up
  # `completions[[goal.id, occurrence_date]]` in O(1) instead of N+1 queries.
  def self.index_for(pairs)
    return {} if pairs.empty?

    where(goal_id: pairs.map(&:first).uniq)
      .index_by { |completion| [ completion.goal_id, completion.occurred_on ] }
      .slice(*pairs)
  end
end
