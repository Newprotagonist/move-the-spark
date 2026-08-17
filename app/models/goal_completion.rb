# The per-occurrence completion log. A single recurring `Goal` row is
# completed many times (once per due day/week); `occurred_on` identifies
# which occurrence this row is for — the exact date for a daily goal, the
# week's Monday for a weekly goal.
class GoalCompletion < ApplicationRecord
  belongs_to :goal

  validates :occurred_on, presence: true, uniqueness: { scope: :goal_id }
  validates :completed_at, presence: true
  validates :points_awarded, numericality: { greater_than_or_equal_to: 0 }
end
